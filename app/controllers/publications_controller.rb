class PublicationsController < ApplicationController
  def index
    @publications = Publication.all
  end

  def new
    @publication = Publication.new
  end

  def create
    @publication = Publication.new(publication_params)
    
    if params[:create_new_conference].present?
      conference = Conference.create(conference_params)
      @publication.conference = conference
    end

    if params[:create_new_journal_issue].present?
      journal_issue = JournalIssue.create(journal_issue_params)
      @publication.journal_issue = journal_issue
    end
    
    if params[:create_kpi_extension].present?
      @publication.build_kpi_reporting_extension(kpi_reporting_extension_params)
    end
    
    if params[:create_open_access_extension].present?
      @publication.build_open_access_extension(open_access_extension_params)
    end

    if @publication.save
      redirect_to @publication, notice: 'Publication was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @publication = Publication.find(params[:id])
  end

  def edit
  end

  def update
  end

  def destroy
    @publication = Publication.find(params[:id])
    @publication.destroy
    
    redirect_to publications_path, notice: "Publication was successfully deleted."
  end

  private

  def publication_params
    params.require(:publication).permit(
      :title, :category, :status, :author_list, :publication_date, :link, :conference_id, :journal_issue_id,
      research_group_publications_attributes: [:id, :research_group, :is_primary, :_destroy],
      identifiers_attributes: [:id, :category, :value, :_destroy],
      repository_links_attributes: [:id, :repository, :value, :_destroy]
    )
  end

  def conference_params
    params.require(:publication).require(:conference).permit(
      :name, :core, :start_date, :end_date
    )
  end

  def journal_issue_params
    params.require(:publication).require(:journal_issue).permit(
      :title, :journal_num, :publisher, :volume, :impact_factor
    )
  end

  def kpi_reporting_extension_params
    params.require(:publication).require(:kpi_reporting_extension).permit(
      :teaming_reporting_period,
      :invoice_number,
      :pbn,
      :jcr,
      :is_added_ft_portal,
      :is_checked,
      :is_new_method_technique,
      :is_methodology_application,
      :is_polish_med_researcher_involved,
      :subsidy_points
    )
  end

  def open_access_extension_params
    params.require(:publication).require(:open_access_extension).permit(
      :category,
      :gold_oa_charges,
      :gold_oa_funding_source
    )
  end
end
