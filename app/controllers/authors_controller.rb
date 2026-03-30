# app/controllers/authors_controller.rb
class AuthorsController < ApplicationController
  before_action :set_author, only: %i[show edit update destroy]
  before_action :authenticate_user!, only: %i[edit update destroy]
  before_action :authorize_moderator!, only: %i[edit update destroy]

  def index
    @q = Author.ransack(params[:q])

    base_scope = @q.result
                    .left_joins(:publication_authorships)
                    .select("authors.*, COUNT(DISTINCT publication_authorships.publication_id) AS publications_count")
                    .group("authors.id")

    sort_param = params[:sort].presence || Authors::SortValidator.default_key
    order = Authors::SortValidator.safe_order(sort_param) || Authors::SortValidator.default_order

    @pagy, @authors = pagy(base_scope.reorder(order))
  end

  def show
    @publications = @author.publications
                           .includes(:conference, :journal_issue)
                           .distinct
                           .order(publication_year: :desc, title: :asc)
  end

  def edit; end

  def update
    if @author.update(author_params)
      respond_to do |format|
        format.html do
          redirect_to author_path(@author, back_params), notice: "Author was successfully updated."
        end

        format.turbo_stream
      end
    else
      render :edit, formats: :html, status: :unprocessable_entity
    end
  end

  def destroy
    @author.destroy
    redirect_to authors_path(back_params), notice: "Author was successfully deleted."
  end

  private

  def set_author
    @author = Author.find(params[:id])
  end

  def authorize_author_edit!
    redirect_to author_path(@author), alert: "You are not authorized to perform this action." unless current_user&.moderator?
  end

  def author_params
    params.require(:author).permit(:author_type, :title, :first_name, :last_name, :collective_name)
  end
end