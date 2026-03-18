require_relative "flexor/version"
require_relative "flexor/hash_delegation"
require_relative "flexor/serialization"
require_relative "flexor/vivification"
require_relative "flexor/case_conversion"
require_relative "flexor/flex_keys"

##
# A Hash-like data store with autovivifying nested access, nil-safe
# chaining, and seamless conversion between hashes and method-style
# access.
class Flexor
  class Error < StandardError; end

  include HashDelegation
  include Serialization
  include Vivification
  include FlexKeys

  def self.[](input = {}, **options)
    flex_keys = options.delete(:flex_keys) { true }
    input = options.merge(input) if input.is_a?(Hash) && !options.empty?

    case input
    when String then from_json(input, flex_keys: flex_keys)
    when Hash then new(input, flex_keys: flex_keys)
    else raise ArgumentError, "expected a String or Hash, got #{input.class}"
    end
  end

  def self.from_json(json, flex_keys: true)
    require "json"
    JSON.parse(json, symbolize_names: true)
        .then { new(it, flex_keys: flex_keys) }
  end

  def self.===(other)
    other.is_a?(self)
  end

  def initialize(hash = {}, root: true, flex_keys: true)
    raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

    @root      = root
    @flex_keys = flex_keys
    @store     = vivify(hash)
  end

  def initialize_copy(original)
    super
    @store = @store.dup
  end

  def [](key)
    @store[resolve_key(key)]
  end

  def []=(key, value)
    @store[resolve_key(key)] = vivify_value(value)
  end

  def set_raw(key, value)
    @store[resolve_key(key)] = value
  end

  def delete(key)
    @store.delete(resolve_key(key))
  end

  def clear
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
    resolved = resolve_key(key)
    cache_setter(name, resolved)
    self[resolved] = arg
  end

  def read_via_method(name)
    resolved = resolve_key(name)
    cache_getter(name, resolved) if !frozen? && @store.key?(resolved)
    self[resolved]
  end

  def cache_setter(name, resolved)
    define_singleton_method(name) do |val = nil, &blk|
      raise NoMethodError, "undefined method '#{name}' for #{inspect}" if blk

      self[resolved] = val
    end
  end

  def cache_getter(name, resolved = name)
    define_singleton_method(name) do |*a, &blk|
      raise NoMethodError, "undefined method '#{name}' for #{inspect}" if blk || !a.empty?

      self[resolved]
    end
  end
end

require_relative "f"
