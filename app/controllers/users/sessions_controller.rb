class Users::SessionsController < Devise::SessionsController
    def new
        render inline:
        <<~ERB, layout: "application"
            <%= form_with url: user_azure_activedirectory_v2_omniauth_authorize_path,
                        method: :post,
                        data: { turbo: false } do %>
            <% end %>
            <script>
                document.querySelector('form').submit();
            </script>
        ERB
    end
end
