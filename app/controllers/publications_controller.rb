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
end
