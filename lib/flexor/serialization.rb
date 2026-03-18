class Flexor
  ##
  # Methods for Marshal and YAML round-trip serialization.
  module Serialization
    def marshal_dump
      { store: to_h, root: @root, flex_keys: @flex_keys }
    end

    def marshal_load(data)
      @root      = data[:root]
      @flex_keys = data[:flex_keys]
      @store     = vivify(data[:store])
    end

    def encode_with(coder)
      coder["store"]     = to_h
      coder["root"]      = @root
      coder["flex_keys"] = @flex_keys
    end

    def init_with(coder)
      @root      = coder["root"]
      @flex_keys = coder["flex_keys"]
      @store     = vivify(symbolize_keys(coder["store"] || {}))
    end

    private

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym).transform_values do |v|
        v.is_a?(Hash) ? symbolize_keys(v) : v
      end
    end
  end
end
