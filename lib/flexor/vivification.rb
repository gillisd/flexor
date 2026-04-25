class Flexor
  ##
  # Methods for recursively converting raw Hashes and Arrays into Flexor objects.
  module Vivification
    private

    def vivify(hash)
      hash.transform_values { |value| vivify_value(value) }
    end

    def vivify_value(value)
      case value
      when Hash then self.class.new(value, root: false)
      when Array then vivify_array(value)
      else value
      end
    end

    def vivify_array(array)
      array.map do |item|
        case item
        when Hash then self.class.new(item, root: false)
        when Array then vivify_array(item)
        else item
        end
      end
    end

    def recurse_to_h(object)
      case object
      in Array then object.map { recurse_to_h(it) }
      in ^(self.class)
        converted = object.to_h
        converted.empty? ? nil : converted
      else object
      end
    end
  end
end
