module ChangeDisplayHelper
    def display_value(value)
        case value
        when true  then "Yes"
        when false then "No"
        when nil   then "-"
        else
          value.respond_to?(:blank?) && value.blank? ? "-" : value.to_s
        end
    end

    def assoc_label(record_class, id)
        @__assoc_label_cache ||= {}
        key = [ record_class.name, id ]
        return @__assoc_label_cache[key] if @__assoc_label_cache.key?(key)

        obj = record_class.find_by(id: id)
        label = obj&.try(:name) || obj&.try(:title) || (id ? "##{id}" : "-")
        @__assoc_label_cache[key] = label
    end

    def display_changed_any(target, field, old_v, new_v)
        f = field.to_s

        klass =
          case target
          when Class  then target
          when String then target.safe_constantize
          else             target&.class
          end

        return [ display_value(old_v), display_value(new_v) ] unless klass

        if f.end_with?("_id")
          assoc_name = f.sub(/_id\z/, "")
          if (ref = klass.reflect_on_association(assoc_name.to_sym))
            old_label = old_v.nil? ? "-" : assoc_label(ref.klass, old_v)
            new_label = new_v.nil? ? "-" : assoc_label(ref.klass, new_v)
            return [ old_label, new_label ]
          end
        end

        if klass.respond_to?(:defined_enums) && klass.defined_enums.key?(f)
          enum_map = klass.defined_enums[f]
          inv      = enum_map.invert
          old_lab  = inv[old_v.to_s]&.humanize || display_value(old_v)
          new_lab  = inv[new_v.to_s]&.humanize || display_value(new_v)
          return [ old_lab, new_lab ]
        end

        [ display_value(old_v), display_value(new_v) ]
    end
end
