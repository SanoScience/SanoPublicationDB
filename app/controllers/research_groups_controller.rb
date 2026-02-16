class ResearchGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_moderator!
  before_action :set_research_group, only: [ :edit, :update, :destroy ]

  def index
    @research_groups = ResearchGroup.order(:name)
  end

  def new
    @research_group = ResearchGroup.new
    respond_to { |f| f.turbo_stream }
  end

  def create
    @research_group = ResearchGroup.new(research_group_params)
    if @research_group.save
      respond_to do |f|
        f.turbo_stream
        f.html { redirect_to research_groups_path, notice: "Research group was successfully created." }
      end
    else
      respond_to do |f|
        f.turbo_stream { render :new, status: :unprocessable_entity }
        f.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to { |f| f.turbo_stream }
  end

  def update
    if @research_group.update(research_group_params)
      respond_to do |f|
        f.turbo_stream
        f.html { redirect_to research_groups_path, notice: "Research group was successfully updated." }
      end
    else
      respond_to do |f|
        f.turbo_stream { render :edit, status: :unprocessable_entity }
        f.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @research_group.destroy
      respond_to do |f|
        f.turbo_stream { render turbo_stream: turbo_stream.remove(@research_group) }
        f.html { redirect_to research_groups_path, notice: "Research group was successfully destroyed." }
      end
    else
      msg = @research_group.errors.full_messages.presence&.to_sentence ||
            "Cannot delete record because dependent research group publications exist"

      respond_to do |f|
        f.turbo_stream do
          flash.now[:alert] = msg
          render turbo_stream: [
            turbo_stream.replace(
              @research_group,
              partial: "research_groups/research_group",
              locals: { research_group: @research_group }
            ),
            turbo_stream.prepend("flash", partial: "layouts/flash")
          ]
        end
        f.html { redirect_to research_groups_path, alert: msg }
      end
    end
  end

  private

  def set_research_group
    @research_group = ResearchGroup.find(params[:id])
  end

  def research_group_params
    params.require(:research_group).permit(:name)
  end

  def require_moderator!
    unless current_user.moderator?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
