class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pagy::Backend

  private

  def back_params
    request.query_parameters.slice("q", "sort", "page")
  end
  helper_method :back_params
end
