class PublicationsController < ApplicationController
  before_action :set_publication, only: %i[show edit update destroy]
  before_action :authenticate_user!, only: %i[new create edit update destroy]
  before_action :authorize_owner!, only: %i[edit update destroy]

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

    order = Publications::SortValidator.safe_order(params[:sort])
    @pagy, @publications = pagy(order ? base_scope.reorder(order) : base_scope)
  end

  def new
    @publication = Publication.new
    @publication.research_group_publications.build
  end

  def create
    @publication = current_user.publications.build(publication_params)
    if @publication.save
      redirect_to @publication, notice: "Publication was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit; end

  def update
    if @publication.update(publication_params)
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
    redirect_to @publication, alert: "You are not authorized to perform this action." unless @publication.owner == current_user
  end

  def publication_params
    params.require(:publication).permit(
      :title, :category, :status, :author_list, :publication_date, :link,
      :conference_id, :journal_issue_id,
      research_group_publications_attributes: [ :id, :research_group_id, :is_primary, :_destroy ],
      identifiers_attributes: [ :id, :category, :value, :_destroy ],
      repository_links_attributes: [ :id, :repository, :value, :_destroy ],
      kpi_reporting_extension_attributes: [ :id, :teaming_reporting_period, :invoice_number, :pbn, :jcr, :is_added_ft_portal, :is_checked, :is_new_method_technique, :is_methodology_application, :is_polish_med_researcher_involved, :is_peer_reviewed, :subsidy_points, :_destroy ],
      open_access_extension_attributes: [ :id, :category, :gold_oa_charges, :gold_oa_funding_source, :_destroy ],
      conference_attributes: [ :id, :name, :core, :start_date, :end_date, :_destroy ],
      journal_issue_attributes: [ :id, :title, :journal_num, :publisher, :volume, :impact_factor, :_destroy ]
    )
  end
end
