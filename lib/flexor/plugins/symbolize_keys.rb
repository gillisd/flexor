class Flexor
  module Plugins
    ##
    # Normalizes string keys to symbols at ingestion and access time.
    # Ensures that data arriving with string keys (from JSON, YAML, or
    # plain Ruby hashes) is accessible via method and symbol-bracket
    # access without manual conversion.
    module SymbolizeKeys
      ##
      # Instance methods that convert string keys to symbols on
      # ingestion (+vivify+, +[]=+) and read (+[]+).
      module StoreMethods
        def [](key)
          super(symbolize_key(key))
        end

        def []=(key, value)
          super(symbolize_key(key), value)
        end

        private

        def symbolize_key(key)
          key.is_a?(String) ? key.to_sym : key
        end

        def vivify(hash)
          super(hash.transform_keys { |k| symbolize_key(k) })
        end
      end

      Flexor.register_plugin(:symbolize_keys, self)
    end
  end
end
