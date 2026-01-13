class PublicationsController < ApplicationController
  before_action :set_publication, only: %i[show edit update destroy]
  before_action :authenticate_user!, only: %i[new create edit update destroy]
  before_action :authorize_owner!, only: %i[edit update destroy]
  before_action :authorize_export!, only: :index, if: -> { request.format.xlsx? }

  def index
    @q = Publication.ransack(params[:q])
    base_scope = @q.result.includes(
      :identifiers,
      :kpi_reporting_extension,
      :open_access_extension,
      :conference,
      :journal_issue,
      { research_group_publications: :research_group }
    ).left_joins(:journal_issue, :conference, :kpi_reporting_extension)

    sort_param = params[:sort].presence || Publications::SortValidator.default_key
    order = Publications::SortValidator.safe_order(sort_param) || Publications::SortValidator.default_order
    @pagy, @publications = pagy(base_scope.reorder(order))

    respond_to do |format|
      format.html
      format.xlsx do
        @publications_for_export = base_scope.reorder(order)
        render xlsx: "publications", template: "exports/excel_export"
      end
    end
  end

  def new
    @publication = Publication.new
    @publication.research_group_publications.build
    @publication.build_kpi_reporting_extension
  end

  def create
    @publication = current_user.publications.build(publication_params)
    if @publication.save(context: :ui)
      NotificationMailer.new_publication_notification(@publication).deliver_now
      redirect_to @publication, notice: "Publication was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit; end

  def update
    @publication.assign_attributes(publication_params)
    if @publication.save(context: :ui)
      payload = @publication.build_notification_payload
      if payload.present?
        NotificationMailer.publication_update_notification(@publication, current_user, payload).deliver_now
        @publication._notification_changes = nil
      end
      redirect_to @publication, notice: "Publication was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @publication.destroy
    redirect_to publications_path, notice: "Publication was successfully deleted."
  end

  private

  def set_publication
    @publication = Publication.find(params[:id])
  end

  def authorize_owner!
    redirect_to @publication, alert: "You are not authorized to perform this action." unless @publication.owner == current_user || current_user&.role == "moderator"
  end

  def authorize_export!
    unless current_user&.role == "moderator"
      redirect_to publications_path, alert: "You are not authorized to export data."
    end
  end

  def publication_params
    raw = params.require(:publication)

    scrub_foreign_destroy_flags(raw)

    permitted = raw.permit(
      :title, :category, :status, :author_list, :publication_year, :link,
      :conference_id, :journal_issue_id,
      research_group_publications_attributes: [ :id, :research_group_id, :is_primary, :_destroy ],
      identifiers_attributes: [ :id, :category, :value, :_destroy ],
      repository_links_attributes: [ :id, :repository, :value, :_destroy ],
      kpi_reporting_extension_attributes: [ :id, :teaming_reporting_period, :invoice_number, :pbn, :jcr, :is_added_ft_portal, :is_checked, :is_new_method_technique, :is_methodology_application, :is_polish_med_researcher_involved, :is_peer_reviewed, :subsidy_points, :is_co_publication_with_partners, :_destroy ],
      open_access_extension_attributes: [ :id, :category, :gold_oa_charges, :gold_oa_funding_source, :_destroy ],
      conference_attributes: [ :id, :name, :core, :start_date, :end_date, :_destroy ],
      journal_issue_attributes: [ :id, :title, :journal_num, :publisher, :volume, :impact_factor, :_destroy ]
    )

    sanitize_nested_for_non_moderator(permitted) unless current_user&.role == "moderator"

    permitted
  end

  def scrub_foreign_destroy_flags(raw)
    return unless @publication&.persisted?
    return unless current_user&.role == "moderator"

    if (conf = raw[:conference_attributes])
      destroy = conf[:_destroy]
      id      = conf[:id]

      if destroy == "1" &&
         id.present? &&
         @publication.conference_id.present? &&
         id.to_s != @publication.conference_id.to_s
        conf[:_destroy] = "0"
      end
    end

    if (ji = raw[:journal_issue_attributes])
      destroy = ji[:_destroy]
      id      = ji[:id]

      if destroy == "1" &&
         id.present? &&
         @publication.journal_issue_id.present? &&
         id.to_s != @publication.journal_issue_id.to_s
        ji[:_destroy] = "0"
      end
    end
  end

  def sanitize_nested_for_non_moderator(permitted)
    if (conf = permitted[:conference_attributes])
      if conf[:id].present?
        permitted.delete(:conference_attributes)
      else
        conf.delete(:_destroy)
      end
    end

    if (ji = permitted[:journal_issue_attributes])
      if ji[:id].present?
        permitted.delete(:journal_issue_attributes)
      else
        ji.delete(:_destroy)
      end
    end
  end
end
