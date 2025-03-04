class PublicationsController < ApplicationController
  def index
    @publications = Publication.all
  end

  def new
    @publication = Publication.new
  end

  def create
    @publication = Publication.new(publication_params)
    
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
      :title, :category, :status, :author_list, :publication_date, :link,
      research_group_publications_attributes: [:research_group, :is_primary],
      identifiers_attributes: [:category, :value],
      repository_links_attributes: [:repository, :value]
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
