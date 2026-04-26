class Flexor
  module Plugins
    ##
    # Core plugin providing all fundamental Flexor behavior.
    # Bundles Vivification, HashDelegation, Serialization, and
    # MethodDispatch along with every instance and class method
    # that ships with a default Flexor install.
    module Core
      ##
      # Instance methods for the core Flexor data store.
      module StoreMethods
        include Flexor::Vivification
        include Flexor::HashDelegation
        include Flexor::Serialization
        include Flexor::MethodDispatch

        def initialize(hash = {}, root: true)
          raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

          @root  = root
          @store = vivify(hash)
        end

        def initialize_copy(original)
          super
          @store = @store.dup
        end

        def [](key)
          value = @store[key]
          return nil if nil_like?(value)

          value
        end

        def []=(key, value)
          @store[key] = vivify_value(value)
        end

        def set_raw(key, value)
          @store[key] = value
        end

        def delete(key)
          uncache_method(key)
          @store.delete(key)
        end

        def clear
          @store.each_key { |key| uncache_method(key) }
          @store.clear
          self
        end

        def to_ary
          nil
        end

        def freeze
          @store.freeze
          super
        end

        def to_h
          @store.each_with_object({}) do |(key, value), hash|
            result = recurse_to_h(value)
            hash[key] = result unless value.is_a?(Flexor) && result.nil?
          end
        end

        def to_json(...)
          require "json"
          to_h.to_json(...)
        end

        def to_s
          return "" if nil?

          @store.to_s
        end

        def inspect
          return @store.inspect if @root
          return nil.inspect if @store.empty?

          @store.inspect
        end

        def deconstruct
          @store.values
        end

        def deconstruct_keys(keys)
          return @store if keys.nil?

          @store.slice(*keys)
        end

        def nil?
          @store.empty?
        end

        def merge!(other)
          other = other.to_h if other.is_a?(Flexor)
          other.each do |key, value|
            if value.is_a?(Hash) && self[key].is_a?(Flexor) && !self[key].nil?
              self[key].merge!(value)
            else
              self[key] = value
            end
          end
          self
        end

        def merge(other)
          dup.merge!(other)
        end

        def ==(other)
          case other
          in nil then nil?
          in Flexor then to_h == other.to_h
          in Hash then to_h == other
          else super
          end
        end

        def ===(other)
          other.nil? ? nil? : super
        end

        private

        def nil_like?(value)
          value.is_a?(Flexor) && value.nil?
        end
      end

      ##
      # Class-level methods for the core Flexor data store.
      module ClassMethods
        def [](input = {})
          case input
          when String then from_json(input)
          when Hash then new(input)
          else raise ArgumentError, "expected a String or Hash, got #{input.class}"
          end
        end

        def from_json(json)
          require "json"
          JSON.parse(json, symbolize_names: true)
              .then { new it }
        end

        def ===(other)
          other.is_a?(self)
        end
      end

      Flexor.register_plugin(:core, self)
    end
  end
end
