module ApplicationHelper
    include Pagy::Frontend

    def yes_no(value)
        return "—" if value.nil?
        value ? "Yes" : "No"
    end
end
