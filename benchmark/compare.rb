require "benchmark/ips"
require "ostruct"
require_relative "../lib/flexor"

begin
  require "hashie"
  Hashie.logger = Logger.new(File::NULL)
  HAS_HASHIE = true
rescue LoadError
  HAS_HASHIE = false
  warn "Hashie not installed skipping Mash benchmarks. Install with: gem install hashie"
end

def hashie_report(bench, label, &block)
  bench.report(label, &block) if HAS_HASHIE
end

FLAT_HASH = { name: "alice", age: 30, city: "NYC" }.freeze
NESTED_HASH = { user: { name: "alice", address: { city: "NYC", zip: "10001" } } }.freeze
DEEP_HASH = { a: { b: { c: { d: { e: "deep" } } } } }.freeze

puts "Ruby #{RUBY_VERSION} (YJIT: #{defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled? ? "enabled" : "disabled"})"
puts "Flexor #{Flexor::VERSION}"
puts "Hashie #{Hashie::VERSION}" if HAS_HASHIE
puts

# --- 1. Construction ---
puts "=" * 60
puts "CONSTRUCTION"
puts "=" * 60

Benchmark.ips do |x|
  x.report("Flexor.new (flat)") { Flexor.new(FLAT_HASH) }
  x.report("Mash.new (flat)")   { Hashie::Mash.new(FLAT_HASH) } if HAS_HASHIE
  x.report("OpenStruct (flat)") { OpenStruct.new(FLAT_HASH) }
  x.compare!
end

puts

Benchmark.ips do |x|
  x.report("Flexor.new (nested)") { Flexor.new(NESTED_HASH) }
  x.report("Mash.new (nested)")   { Hashie::Mash.new(NESTED_HASH) } if HAS_HASHIE
  x.report("OpenStruct (nested)") { OpenStruct.new(NESTED_HASH) }
  x.compare!
end

# --- 2. Reading (method access) ---
puts
puts "=" * 60
puts "READING (method access)"
puts "=" * 60

flexor  = Flexor.new(FLAT_HASH)
mash    = HAS_HASHIE ? Hashie::Mash.new(FLAT_HASH) : nil
ostruct = OpenStruct.new(FLAT_HASH)

Benchmark.ips do |x|
  x.report("Flexor#name")       { flexor.name }
  x.report("Mash#name")         { mash.name } if HAS_HASHIE
  x.report("OpenStruct#name")   { ostruct.name }
  x.compare!
end

# --- 3. Reading (nested chaining) ---
puts
puts "=" * 60
puts "READING (nested chaining)"
puts "=" * 60

flexor_nested = Flexor.new(NESTED_HASH)
mash_nested   = HAS_HASHIE ? Hashie::Mash.new(NESTED_HASH) : nil

Benchmark.ips do |x|
  x.report("Flexor chain") { flexor_nested.user.address.city }
  x.report("Mash chain")   { mash_nested.user.address.city } if HAS_HASHIE
  x.compare!
end

# --- 4. Writing ---
puts
puts "=" * 60
puts "WRITING (method setter)"
puts "=" * 60

Benchmark.ips do |x|
  f = Flexor.new
  m = HAS_HASHIE ? Hashie::Mash.new : nil
  o = OpenStruct.new

  x.report("Flexor#name=")       { f.name = "bob" }
  x.report("Mash#name=")         { m.name = "bob" } if HAS_HASHIE
  x.report("OpenStruct#name=")   { o.name = "bob" }
  x.compare!
end

# --- 5. Writing (hash assignment with vivification) ---
puts
puts "=" * 60
puts "WRITING (hash assignment)"
puts "=" * 60

Benchmark.ips do |x|
  x.report("Flexor []= hash") {
    f = Flexor.new
    f[:config] = { db: { host: "localhost" } }
  }
  hashie_report(x, "Mash []= hash") { Hashie::Mash.new.tap { |m| m[:config] = { db: { host: "localhost" } } } }
  x.compare!
end

# --- 6. Deep autovivification ---
puts
puts "=" * 60
puts "AUTOVIVIFICATION (deep write)"
puts "=" * 60

Benchmark.ips do |x|
  x.report("Flexor a.b.c.d=") {
    f = Flexor.new
    f.a.b.c.d = "deep"
  }
  hashie_report(x, "Mash a!.b!.c!.d=") { Hashie::Mash.new.tap { |m| m.a!.b!.c!.d = "deep" } }
  x.compare!
end

# --- 7. to_h conversion ---
puts
puts "=" * 60
puts "CONVERSION (to_h)"
puts "=" * 60

flexor_deep  = Flexor.new(DEEP_HASH)
mash_deep    = HAS_HASHIE ? Hashie::Mash.new(DEEP_HASH) : nil
ostruct_flat = OpenStruct.new(FLAT_HASH)

Benchmark.ips do |x|
  x.report("Flexor#to_h (deep)") { flexor_deep.to_h }
  x.report("Mash#to_h (deep)")   { mash_deep.to_h } if HAS_HASHIE
  x.report("OpenStruct#to_h")    { ostruct_flat.to_h }
  x.compare!
end

# --- 8. Deep merge ---
puts
puts "=" * 60
puts "DEEP MERGE"
puts "=" * 60

flexor_base = Flexor.new({ db: { host: "localhost", port: 5432 }, log: "info" })
mash_base   = HAS_HASHIE ? Hashie::Mash.new({ db: { host: "localhost", port: 5432 }, log: "info" }) : nil
override    = { db: { port: 3306, name: "mydb" }, log: "debug" }

Benchmark.ips do |x|
  x.report("Flexor#merge") { flexor_base.merge(override) }
  x.report("Mash#merge")   { mash_base.merge(override) } if HAS_HASHIE
  x.compare!
end

# --- 9. Missing key access ---
puts
puts "=" * 60
puts "MISSING KEY ACCESS"
puts "=" * 60

flexor_empty = Flexor.new
mash_empty   = HAS_HASHIE ? Hashie::Mash.new : nil

Benchmark.ips do |x|
  x.report("Flexor missing") { flexor_empty.nope }
  x.report("Mash missing")   { mash_empty.nope } if HAS_HASHIE
  x.compare!
end
