class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def azure_activedirectory_v2
      auth_info = request.env["omniauth.auth"]

      if auth_info.dig("extra", "raw_info", "tid") != ENV["AZURE_TENANT_ID"]
        redirect_to root_path, alert: "Access denied: not part of this organization." and return
      end

      @user = User.from_omniauth(auth_info)

      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Microsoft") if is_navigational_format?
    end

    def failure
      redirect_to root_path
    end
end
