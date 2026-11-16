class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def entra_id
    auth_info = request.env["omniauth.auth"]

    if auth_info.dig("extra", "raw_info", "tid") != ENV["ENTRA_TENANT_ID"]
      redirect_to root_path, alert: "Access denied: not part of this organization."
      return
    end

    @user = User.from_omniauth(auth_info)

    if @user.persisted?
      set_flash_message(:notice, :success, kind: "Microsoft") if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.entra_id_data"] = auth_info.except(:extra)
      redirect_to root_path, alert: "Could not authenticate from Microsoft account."
    end
  end

  def failure
    redirect_to root_path, alert: "Authentication failed or was cancelled."
  end
end
