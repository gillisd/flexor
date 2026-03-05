# Flexor

A Hash-like data store that does what you tell it to do.

Flexor gives you autovivifying nested access, nil-safe chaining, and seamless conversion between hashes and method-style access. Built for spikes, prototyping, and anywhere you need a flexible data container without upfront schema design.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add flexor

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install flexor

## Usage

### Construction

From a hash:

```ruby
store = Flexor.new({ user: { name: "Alice", address: { city: "NYC" } } })
store.user.name           # => "Alice"
store.user.address.city   # => "NYC"
```

From JSON:

```ruby
store = Flexor.from_json('{"api": {"version": 2}}')
store.api.version   # => 2
```

### Accessing Properties

Method access and bracket access are interchangeable:

```ruby
store = Flexor.new({ name: "Alice" })
store.name      # => "Alice"
store[:name]    # => "Alice"
```

Nested chaining works to any depth:

```ruby
store = Flexor.new
store.config.database.host = "localhost"
store.config.database.port = 5432
store.config.database.host   # => "localhost"
```

### Safe Chaining

Accessing an unset property returns a nil-like Flexor instead of raising. You can chain as deep as you want without guard clauses:

```ruby
store = Flexor.new
store.anything.deeply.nested.nil?   # => true
store.missing == nil                # => true
store.missing.to_s                  # => ""
"Hello #{store.ghost}"              # => "Hello "
```

### Assignment Vivifies

When you assign a hash or array of hashes, Flexor auto-converts them so chaining continues to work:

```ruby
store = Flexor.new
store.config = { db: { host: "localhost" } }
store.config.db.host   # => "localhost"
store[:config].class   # => Flexor

store.items = [{ id: 1 }, { id: 2 }]
store.items.first.id   # => 1
```

If you need to store a raw Hash without conversion, use `set_raw`:

```ruby
store = Flexor.new
store.set_raw(:headers, { "Content-Type" => "application/json" })
store[:headers].class   # => Hash
```

### Converting Back

`to_h` recursively converts back to plain hashes. Round-trips are lossless:

```ruby
original = { users: [{ name: "Bob" }], meta: { version: 1 } }
Flexor.new(original).to_h == original   # => true
```

Autovivified-but-never-written paths don't appear in `to_h`:

```ruby
store = Flexor.new({ real: "data" })
store.phantom.deep.chain   # read-only access
store.to_h                 # => { real: "data" }
```

### Pattern Matching

Hash patterns via `deconstruct_keys`:

```ruby
config = Flexor.new({ db: { host: "pg", port: 5432 }, cache: "redis" })

case config
in { db: { host: String => host }, cache: "redis" }
  puts "db host=#{host}, cache=redis"
end
```

Array patterns via `deconstruct`:

```ruby
point = Flexor.new({ x: 3, y: 4 })

case point
in [Integer => x, Integer => y]
  puts "Point(#{x}, #{y})"
end
```

### Hash-like Methods

```ruby
store = Flexor.new({ a: 1, b: 2, c: 3 })
store.keys       # => [:a, :b, :c]
store.values     # => [1, 2, 3]
store.size       # => 3
store.empty?     # => false
store.key?(:a)   # => true

store.each { |k, v| puts "#{k}: #{v}" }
store.map { |k, v| [k, v * 10] }
store.select { |_k, v| v > 1 }
```

### Equality

```ruby
Flexor.new({ x: 1 }) == Flexor.new({ x: 1 })   # => true
Flexor.new({ x: 1 }) == { x: 1 }                # => true
Flexor.new == nil                                 # => true
```

### Freezing

```ruby
store = Flexor.new({ locked: true })
store.freeze
store.locked       # => true
store.new_key = 1  # => FrozenError
```

### Copying

`dup` and `clone` create shallow copies:

```ruby
original = Flexor.new({ a: 1 })
copy = original.dup
copy.b = 2
original.key?(:b)   # => false
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. Run `rake` to run both tests and rubocop.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
