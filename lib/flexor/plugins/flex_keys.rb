class Flexor
  module Plugins
    ##
    # CamelCase/snake_case key resolution plugin. Overrides key-accepting
    # methods to check for an alternate-case match when the exact key is
    # not found. Composes via +super+ with Core (or any plugin below it).
    module FlexKeys
      ##
      # Instance methods that resolve symbol keys to their alternate-case
      # counterpart before delegating to the underlying store.
      module StoreMethods
        def [](key)
          super(resolve_flex_key(key))
        end

        def []=(key, value)
          super(resolve_flex_key(key), value)
        end

        def set_raw(key, value)
          super(resolve_flex_key(key), value)
        end

        def delete(key)
          super(resolve_flex_key(key))
        end

        def key?(key)
          super(resolve_flex_key(key))
        end

        def deconstruct_keys(keys)
          return super if keys.nil?

          keys.each_with_object({}) do |key, hash|
            resolved = resolve_flex_key(key)
            hash[key] = @store[resolved] if @store.key?(resolved)
          end
        end

        private

        def resolve_flex_key(key)
          return key if @store.key?(key)
          return key unless key.is_a?(Symbol)

          alt = CaseConversion.case_counterpart(key)
          alt && @store.key?(alt) ? alt : key
        end

        def read_via_method(name)
          resolved = resolve_flex_key(name)
          cache_getter(name, resolved) if !frozen? && @store.key?(resolved)
          return @store[resolved] if @store.key?(resolved)

          super
        end
      end

      Flexor.register_plugin(:flex_keys, self)
    end
  end
end
