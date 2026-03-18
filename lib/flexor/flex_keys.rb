class Flexor
  ##
  # Opt-in key resolution across camelCase and snake_case. When enabled via
  # +flex_keys: true+, symbol keys are resolved to their alternate-case
  # equivalent if the exact key is not found in the store.
  module FlexKeys
    private

    def resolve_key(key)
      return key unless @flex_keys
      return key if @store.key?(key)
      return key unless key.is_a?(Symbol)

      alt = CaseConversion.alternate_key(key)
      alt && @store.key?(alt) ? alt : key
    end
  end
end
