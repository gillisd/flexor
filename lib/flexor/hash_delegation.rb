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
    alias has_key? key?

    def each(&)
      @store.each(&)
    end

    def each_key(&)
      @store.each_key(&)
    end

    def map(&)
      @store.map(&)
    end

    def select(&)
      @store.select(&)
    end
  end
end
