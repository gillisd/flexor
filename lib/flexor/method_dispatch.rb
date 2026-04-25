class Flexor
  ##
  # Handles dynamic getter/setter dispatch via method_missing and
  # caches singleton methods for repeated access.
  module MethodDispatch
    def respond_to_missing?(_name, _include_private = false)
      true
    end

    private

    def method_missing(name, *args, &block)
      return super if block

      case [name, args]
      in /^[^=]+=$/, [arg] then write_via_method(name, arg)
      in _, [] then read_via_method(name)
      else super
      end
    end

    def write_via_method(name, arg)
      key = name.to_s.chomp("=").to_sym
      cache_setter(name, key)
      self[key] = arg
    end

    def read_via_method(name)
      cache_getter(name) if !frozen? && @store.key?(name)
      return @store[name] if @store.key?(name)

      @store[name] = self.class.new({}, root: false)
    end

    def cache_setter(name, key)
      define_singleton_method(name) do |val = nil, &blk|
        raise NoMethodError, "undefined method '#{name}' for #{inspect}" if blk

        self[key] = val
      end
    end

    def cache_getter(name, key = name)
      define_singleton_method(name) do |*a, &blk|
        raise NoMethodError, "undefined method '#{name}' for #{inspect}" if blk || !a.empty?

        @store[key]
      end
    end
  end
end
