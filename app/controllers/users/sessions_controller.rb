class Users::SessionsController < Devise::SessionsController
    def new
        redirect_to user_azure_activedirectory_v2_omniauth_authorize_path
    end
end