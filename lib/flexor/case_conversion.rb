class Flexor
  ##
  # Pure-function utilities for converting between camelCase and snake_case.
  # Core logic adapted from ActiveSupport::Inflector, without the acronyms
  # infrastructure. Always produces lowerCamelCase since that is what JSON
  # APIs use.
  module CaseConversion
    CAMEL_BOUNDARY = /(?<=[A-Z])(?=[A-Z][a-z])|(?<=[a-z\d])(?=[A-Z])/

    module_function

    def camelize(term)
      string = term.to_s.dup
      return string if string.empty?

      string.gsub!(%r{(?:_|(/))([a-z\d]*)}) do
        "#{Regexp.last_match(1) && "::"}#{Regexp.last_match(2).capitalize}"
      end
      string[0] = string[0].downcase
      string
    end

    def underscore(camel_cased_word)
      return camel_cased_word.to_s.dup unless /[A-Z-]/.match?(camel_cased_word)

      word = camel_cased_word.to_s.dup
      word.gsub!(CAMEL_BOUNDARY, "_")
      word.tr!("-", "_")
      word.downcase!
      word
    end

    def alternate_key(key)
      str = key.to_s
      if str.include?("_")
        camelize(str).to_sym
      elsif str.match?(/[A-Z]/)
        underscore(str).to_sym
      end
    end
  end
end
