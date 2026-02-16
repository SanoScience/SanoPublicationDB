module UrlValidatable
  extend ActiveSupport::Concern

  class_methods do
    def validates_url_of(*attributes)
      attributes.each do |attribute|
        before_validation do
          value = send(attribute)
          next if value.blank?

          cleaned = value.strip
          begin
            uri = URI.parse(cleaned)
            unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
              errors.add(attribute, "must be a valid HTTP/HTTPS URL")
            else
              send("#{attribute}=", uri.to_s)
            end
          rescue URI::InvalidURIError
            errors.add(attribute, "must be a valid URL")
          end
        end
      end
    end
  end
end
