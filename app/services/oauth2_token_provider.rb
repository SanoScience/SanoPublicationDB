# app/services/oauth2_token_provider.rb
require 'oauth2'

class Oauth2TokenProvider
  class << self
    def access_token
      refresh_token_if_needed
      @token
    end

    private

    def refresh_token_if_needed
      if @token.nil? || Time.now >= @expires_at
        begin
          new_token = client.client_credentials.get_token(
            scope: 'https://outlook.office365.com/.default'
          )
          @token = new_token.token
          @expires_at = Time.now + new_token.expires_in.seconds
        rescue OAuth2::Error => e
          puts "⚠️ OAuth2 error:"
          puts "  Status: #{e.response.status}"
          puts "  Headers: #{e.response.headers.inspect}"
          puts "  Body: #{e.response.body}"
          raise
        end
      end
    end

    def client
      url = "https://login.microsoftonline.com/#{ENV['ENTRA_TENANT_ID']}"
      puts "🔍 Token request URL: #{url}/oauth2/v2.0/token"
      OAuth2::Client.new(
        ENV['ENTRA_CLIENT_ID'],
        ENV['ENTRA_CLIENT_SECRET'],
        site: "https://login.microsoftonline.com/#{ENV['ENTRA_TENANT_ID']}",
        token_url: "/oauth2/v2.0/token"
      )
    end
  end
end
