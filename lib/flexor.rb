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
                      when Array then value.map { |item|
                        item.is_a?(Hash) ? new(item, root: false) : item
                      }
                      else value
                      end
    end

    new_hash
  end

  def self.from_json(json)
    require "json"
    JSON.parse(json, symbolize_names: true)
      .then { new it }
  end

  def initialize(hash = {}, root: true)
    raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

    @root  = root
    @store = self.class.vivify(hash)
  end

  def [](key)
    @store[key]
  end

  def []=(key, value)
    @store[key] = value
  end

  def to_ary
    # called on #puts, this prevents it from going to method missing
    nil
  end

  def to_h
    @store.each_with_object({}) do |(key, value), hash|
      result = recurse_to_h(value)
      hash[key] = result unless value.is_a?(Flexor) && result.nil?
    end
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

  def each(&block)
    @store.each(&block)
  end

  def each_key(&block)
    @store.each_key(&block)
  end

  def map(&block)
    @store.map(&block)
  end

  def select(&block)
    @store.select(&block)
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

  def self.===(other)
    other.is_a?(self)
  end

  private

  def recurse_to_h(object)
    case object
    in Array then object.map { recurse_to_h(it) }
    in ^(self.class)
      converted = object.to_h
      converted.empty? ? nil : converted
    else object
    end
  end

  def method_missing(name, *args, &block)
    return super if block

    case [name, args]
    in /^[^=]+=$/, [arg]
      self[name.to_s.chomp("=").to_sym] = arg
    in _, []
      self[name]
    else
      super
    end
  end

  def respond_to_missing?(_name, _include_private = false)
    true
  end
end
