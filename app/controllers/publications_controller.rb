class PublicationsController < ApplicationController
  def index
    @publications = Publication.all
  end

  def new
    @publication = Publication.new
  end

  def create
    @publication = Publication.new(publication_params)

    if @publication.save
      redirect_to @publication, notice: "Publication was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @publication = Publication.find(params[:id])
  end

  def edit
    @publication = Publication.find(params[:id])
  end

  def update
    @publication = Publication.find(params[:id])

    if @publication.update(publication_params)
      redirect_to @publication, notice: "Publication was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @publication = Publication.find(params[:id])
    @publication.destroy

    redirect_to publications_path, notice: "Publication was successfully deleted."
  end

  private

  def publication_params
    params.require(:publication).permit(
      :title, :category, :status, :author_list, :publication_date, :link,
      :conference_id, :journal_issue_id,
      research_group_publications_attributes: [ :id, :research_group, :is_primary, :_destroy ],
      identifiers_attributes: [ :id, :category, :value, :_destroy ],
      repository_links_attributes: [ :id, :repository, :value, :_destroy ],
      kpi_reporting_extension_attributes: [ :id, :teaming_reporting_period, :invoice_number, :pbn, :jcr, :is_added_ft_portal, :is_checked, :is_new_method_technique, :is_methodology_application, :is_polish_med_researcher_involved, :is_peer_reviewed, :subsidy_points, :_destroy ],
      open_access_extension_attributes: [ :id, :category, :gold_oa_charges, :gold_oa_funding_source, :_destroy ],
      conference_attributes: [ :id, :name, :core, :start_date, :end_date, :_destroy ],
      journal_issue_attributes: [ :id, :title, :journal_num, :publisher, :volume, :impact_factor, :_destroy ]
    )
  end
end
