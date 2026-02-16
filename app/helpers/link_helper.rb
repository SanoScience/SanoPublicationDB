module LinkHelper
    def safe_url(url)
      return "" if url.blank?
      begin
        uri = URI.parse(url.strip)
        return "invalid URL" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        uri.to_s
      rescue URI::InvalidURIError
        "invalid URL"
      end
    end
end
