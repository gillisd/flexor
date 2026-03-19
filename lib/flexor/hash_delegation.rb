class Flexor
  ##
  # Methods that delegate directly to the underlying Hash store.
  module HashDelegation
    def empty?
      @store.empty?
    end

    def keys
      @store.keys
    end

    def values
      @store.values
    end

    def size
      @store.size
    end

    def length
      @store.length
    end

    def key?(key)
      @store.key?(key)
    end

    def has_key?(key)
      key?(key)
    end
  end
end
