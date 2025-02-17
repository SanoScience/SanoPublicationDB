class PublicationsController < ApplicationController
  def index
    @publications = Publication.all
  end

  def new
  end

  def create
  end

  def show
    @publication = Publication.find(params[:id])
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
