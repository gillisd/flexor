require "zeitwerk"

class Flexor
  LOADER = Zeitwerk::Loader.for_gem
  LOADER.setup

  class Error < StandardError; end

  # Recursively converts a plain Hash into an autovivifying Hash
  # where every nested Hash becomes a FlexStore.
  def self.vivify(original_hash)
    # The default_proc is the heart of autovivification:
    # accessing a missing key auto-creates a new FlexStore.
    new_hash = Hash.new do |hash, key|
      hash[key] = new({}, root: false)
    end

    original_hash.each do |key, value|
      new_hash[key] = case value
                      when Hash  then new(value, root: false)
                      when Array then vivify_array(value)
                      else value
                      end
    end

    new_hash
  end

  def self.vivify_array(array)
    array.map do |item|
      case item
      when Hash then new(item, root: false)
      when Array then vivify_array(item)
      else item
      end
    end
  end

  def self.from_json(json)
    require "json"
    JSON.parse(json, symbolize_names: true)
      .then { new it }
  end

  def self.===(other)
    other.is_a?(self)
  end

  def initialize(hash = {}, root: true)
    raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

    @root  = root
    @store = self.class.vivify(hash)
  end

  def initialize_copy(original)
    super
    @store = @store.dup
  end

  def [](key)
    @store[key]
  end

  def []=(key, value)
    @store[key] = vivify_value(value)
  end

  def set_raw(key, value)
    @store[key] = value
  end

  def delete(key)
    @store.delete(key)
  end

  def to_ary
    nil
  end

  def to_a
    @store.to_a
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

  def respond_to_missing?(_name, _include_private = false)
    true
  end

  private

  def vivify_value(value)
    case value
    when Hash then self.class.new(value, root: false)
    when Array then self.class.vivify_array(value)
    else value
    end
  end

  def recurse_to_h(object)
    case object
    in Array then object.map { recurse_to_h(it) }
    in ^(self.class)
      converted = object.to_h
      converted.empty? ? nil : converted
    else object
    end
  end

  def method_missing(name, *args, &block) # rubocop:disable Metrics/CyclomaticComplexity
    return super if block

    case [name, args]
    in /^[^=]+=$/, [arg]
      key = name.to_s.chomp("=").to_sym
      define_singleton_method(name) do |val = nil, &blk|
        raise NoMethodError, "undefined method '#{name}' for #{inspect}" if blk

        self[key] = val
      end
      self[key] = arg
    in _, []
      unless frozen?
        define_singleton_method(name) do |*a, &blk|
          raise NoMethodError, "undefined method '#{name}' for #{inspect}" if blk || !a.empty?

          self[name]
        end
      end
      self[name]
    else
      super
    end
  end
end
