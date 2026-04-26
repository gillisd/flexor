class Flexor
  ##
  # Methods for Marshal and YAML round-trip serialization.
  module Serialization
    def marshal_dump
      { store: to_h, root: @root }
    end

    def marshal_load(data)
      @root = data[:root]
      @store = vivify(data[:store])
    end

    def encode_with(coder)
      coder["store"] = to_h
      coder["root"] = @root
    end

    def init_with(coder)
      @root = coder["root"]

      @store = coder.then { it["store"] || {} }
                    .then { symbolize_keys it }
                    .then { vivify it }
    end

    private

    def symbolize_keys(hash)
      hash
        .transform_keys(&:to_sym)
        .transform_values do |v|
        v.is_a?(Hash) ? symbolize_keys(v) : v
      end
    end
  end
end
