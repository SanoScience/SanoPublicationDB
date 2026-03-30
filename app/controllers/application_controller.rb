class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pagy::Backend

  private

  def back_params(except: [])
    state = request.query_parameters.slice("q", "sort", "page").deep_dup

    q = state["q"]
    unless q.nil? || q.is_a?(Hash) || q.is_a?(ActionController::Parameters)
      state.delete("q")
    end

    state.except(*Array(except).map(&:to_s))
  end
  helper_method :back_params
end
