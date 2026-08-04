class CitationCountsController < ApplicationController
  before_action :authenticate_user!
  
  def destroy
    unless current_user.moderator?
      redirect_to root_path, alert: "Not authorized"
      return
    end

    @citation_count = CitationCount.find(params[:id])
    @citation_count.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@citation_count) }
      format.html { redirect_back fallback_location: root_path, notice: "Citation record deleted." }
    end
  end
end
