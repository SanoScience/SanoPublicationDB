module ApplicationHelper
    include Pagy::Frontend

    def display_value(value)
        case value
        when true  then "Yes"
        when false then "No"
        when nil   then "-"
        else
            value.respond_to?(:blank?) && value.blank? ? "-" : value.to_s
        end
    end      
end
