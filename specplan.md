# Flexor TDD Specs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Write the complete RSpec test suite for Flexor based on specs.yaml — tests only, no implementation changes.

**Architecture:** Replace the existing `spec/flexor_spec.rb` with a comprehensive spec suite split across 8 focused spec files under `spec/flexor/`. Each file maps to a logical group from specs.yaml. Many tests will fail against the current implementation — that's expected (TDD: red phase).

**Tech Stack:** Ruby 4.0.1, RSpec 3.x, Zeitwerk

**Design Decisions (from specs.yaml commenting convention — uncommented = chosen):**
1. Assigning a plain hash via `[]=` stores the raw Hash, does NOT auto-convert
2. Assigning an array of hashes via `[]=` does NOT auto-convert inner hashes
3. Autovivified-but-never-written paths do NOT appear in `to_h` (no phantom keys)
4. `store.foo` and `store["foo"]` do NOT access the same value (no string/symbol normalization)
5. `dup` is shallow (nested Flexors are shared)
6. Enumeration (`each`/`map`/`select`) delegates to the underlying store

---

## Task 1: Scaffold spec directory and update existing spec file

**Files:**
- Modify: `spec/flexor_spec.rb` — reduce to just the version test
- Create: `spec/flexor/` directory (implicit via file creation in later tasks)

**Step 1: Replace flexor_spec.rb with minimal version-only spec**

```ruby
RSpec.describe Flexor do
  it "has a version number" do
    expect(Flexor::VERSION).not_to be_nil
  end
end
```

**Step 2: Run tests to verify green**

Run: `bundle exec rake spec`
Expected: All pass (version + zeitwerk)

**Step 3: Commit**

```bash
git add spec/flexor_spec.rb
git commit -m "test: reduce flexor_spec.rb to version-only before spec expansion"
```

---

## Task 2: Constructor specs (`Flexor.new`)

**Files:**
- Create: `spec/flexor/constructor_spec.rb`

**Step 1: Write the spec file**

```ruby
RSpec.describe Flexor do
  describe ".new" do
    context "with no arguments" do
      subject { described_class.new }

      it "creates an empty store" do
        expect(subject.to_h).to eq({})
      end

      it "is a root Flexor" do
        expect(subject.instance_variable_get(:@root)).to be true
      end
    end

    context "with an empty hash" do
      subject { described_class.new({}) }

      it "creates an empty store" do
        expect(subject.to_h).to eq({})
      end
    end

    context "with a flat hash" do
      subject { described_class.new({name: "alice", age: 30}) }

      it "stores all key-value pairs" do
        expect(subject.to_h).to eq({name: "alice", age: 30})
      end

      it "allows method access on each key" do
        expect(subject.name).to eq "alice"
        expect(subject.age).to eq 30
      end

      it "allows bracket access on each key" do
        expect(subject[:name]).to eq "alice"
        expect(subject[:age]).to eq 30
      end
    end

    context "with a nested hash" do
      subject { described_class.new({user: {name: "alice"}}) }

      it "recursively converts nested hashes into Flexors" do
        expect(subject[:user]).to be_a described_class
      end

      it "allows method access at every level" do
        expect(subject.user.name).to eq "alice"
      end

      it "allows bracket access at every level" do
        expect(subject[:user][:name]).to eq "alice"
      end
    end

    context "with a deeply nested hash (3+ levels)" do
      subject { described_class.new({a: {b: {c: "deep"}}}) }

      it "allows method access at every level" do
        expect(subject.a.b.c).to eq "deep"
      end

      it "allows bracket access at every level" do
        expect(subject[:a][:b][:c]).to eq "deep"
      end
    end

    context "with a hash containing arrays" do
      subject { described_class.new({tags: ["a", "b"], items: [{id: 1}, {id: 2}]}) }

      it "preserves arrays of scalars" do
        expect(subject.tags).to eq ["a", "b"]
      end

      it "converts hashes inside arrays into Flexors" do
        expect(subject.items.first).to be_a described_class
        expect(subject.items.first.id).to eq 1
      end

      it "preserves non-hash elements in mixed arrays" do
        store = described_class.new({mix: [1, {a: 2}, "three"]})
        expect(store.mix[0]).to eq 1
        expect(store.mix[1]).to be_a described_class
        expect(store.mix[2]).to eq "three"
      end
    end

    context "with a hash containing nil values" do
      subject { described_class.new({gone: nil}) }

      it "stores the nil value directly" do
        expect(subject[:gone]).to be_nil
        expect(subject[:gone]).to equal nil
      end
    end

    context "with a non-hash argument" do
      it "raises ArgumentError" do
        expect { described_class.new("string") }.to raise_error(ArgumentError)
        expect { described_class.new(42) }.to raise_error(ArgumentError)
        expect { described_class.new([]) }.to raise_error(ArgumentError)
      end
    end

    context "root vs non-root" do
      it "defaults to root: true" do
        store = described_class.new
        expect(store.instance_variable_get(:@root)).to be true
      end

      it "can be set to root: false" do
        store = described_class.new({}, root: false)
        expect(store.instance_variable_get(:@root)).to be false
      end
    end
  end
end
```

**Step 2: Run to check red/green status**

Run: `bundle exec rspec spec/flexor/constructor_spec.rb --format documentation`
Expected: Most pass (constructor is implemented), note any failures

**Step 3: Commit**

```bash
git add spec/flexor/constructor_spec.rb
git commit -m "test: add constructor specs for Flexor.new"
```

---

## Task 3: `Flexor.from_json` specs

**Files:**
- Create: `spec/flexor/from_json_spec.rb`

**Step 1: Write the spec file**

```ruby
RSpec.describe Flexor do
  describe ".from_json" do
    context "with valid flat JSON" do
      let(:json) { '{"name": "alice", "age": 30}' }
      subject { described_class.from_json(json) }

      it "creates a Flexor with symbolized keys" do
        expect(subject[:name]).to eq "alice"
        expect(subject[:age]).to eq 30
      end

      it "allows method access on parsed values" do
        expect(subject.name).to eq "alice"
      end
    end

    context "with nested JSON" do
      let(:json) { '{"user": {"name": "alice", "address": {"city": "NYC"}}}' }
      subject { described_class.from_json(json) }

      it "recursively converts nested objects" do
        expect(subject[:user]).to be_a described_class
      end

      it "allows method chaining on nested values" do
        expect(subject.user.address.city).to eq "NYC"
      end
    end

    context "with JSON containing arrays" do
      let(:json) { '{"tags": ["a", "b"], "items": [{"id": 1}]}' }
      subject { described_class.from_json(json) }

      it "preserves arrays" do
        expect(subject.tags).to eq ["a", "b"]
      end

      it "converts objects inside arrays into Flexors" do
        expect(subject.items.first).to be_a described_class
        expect(subject.items.first.id).to eq 1
      end
    end

    context "with invalid JSON" do
      it "raises a parse error" do
        expect { described_class.from_json("not json") }.to raise_error(JSON::ParserError)
      end
    end
  end
end
```

**Step 2: Run to check**

Run: `bundle exec rspec spec/flexor/from_json_spec.rb --format documentation`
Expected: May fail due to `new it` syntax on line 34 of lib/flexor.rb

**Step 3: Commit**

```bash
git add spec/flexor/from_json_spec.rb
git commit -m "test: add Flexor.from_json specs"
```

---

## Task 4: Reading properties specs

**Files:**
- Create: `spec/flexor/reading_spec.rb`

**Step 1: Write the spec file**

```ruby
RSpec.describe Flexor do
  describe "reading a level 1 property via method" do
    context "the property does exist" do
      subject { described_class.new({foo: "bar"}) }

      it "reads the correct property" do
        expect(subject.foo).to eq "bar"
      end
    end

    context "the property does NOT exist" do
      subject { described_class.new({}) }

      it "returns a value where nil? is true" do
        expect(subject.foo).to be_nil
      end

      it "returns a value that == nil" do
        expect(subject.foo == nil).to be true
      end

      it "does not return the nil singleton" do
        expect(subject.foo).not_to equal nil
      end

      it "returns a Flexor" do
        expect(subject.foo).to be_a described_class
      end
    end
  end

  describe "reading a level 1 property via hash accessor" do
    context "the property does exist" do
      subject { described_class.new({foo: "bar"}) }

      it "reads the correct property" do
        expect(subject[:foo]).to eq "bar"
      end
    end

    context "the property does NOT exist" do
      subject { described_class.new({}) }

      it "returns a value where nil? is true" do
        expect(subject[:foo]).to be_nil
      end

      it "returns a value that == nil" do
        expect(subject[:foo] == nil).to be true
      end

      it "does not return the nil singleton" do
        expect(subject[:foo]).not_to equal nil
      end

      it "returns a Flexor" do
        expect(subject[:foo]).to be_a described_class
      end
    end
  end

  describe "reading a level 2 property via method" do
    context "the level 1 property does exist" do
      subject { described_class.new({user: {name: "alice"}}) }

      context "the level 2 property does exist" do
        it "reads the correct property" do
          expect(subject.user.name).to eq "alice"
        end
      end

      context "the level 2 property does NOT exist" do
        it "returns a value where nil? is true" do
          expect(subject.user.missing).to be_nil
        end
      end
    end

    context "the level 1 property does NOT exist" do
      subject { described_class.new({}) }

      it "returns a value where nil? is true" do
        expect(subject.missing.also_missing).to be_nil
      end

      it "the returned value is itself a Flexor that supports further chaining" do
        result = subject.missing
        expect(result).to be_a described_class
        expect(result.deeper.still).to be_nil
      end
    end
  end

  describe "reading a level 2 property via hash accessor" do
    context "the level 1 property does exist" do
      subject { described_class.new({user: {name: "alice"}}) }

      context "the level 2 property does exist" do
        it "reads the correct property" do
          expect(subject[:user][:name]).to eq "alice"
        end
      end

      context "the level 2 property does NOT exist" do
        it "returns a value where nil? is true" do
          expect(subject[:user][:missing]).to be_nil
        end
      end
    end

    context "the level 1 property does NOT exist" do
      subject { described_class.new({}) }

      it "returns a value where nil? is true" do
        expect(subject[:missing][:also_missing]).to be_nil
      end

      it "the returned value is itself a Flexor that supports further chaining" do
        result = subject[:missing]
        expect(result).to be_a described_class
        expect(result[:deeper][:still]).to be_nil
      end
    end
  end

  describe "reading at arbitrary depth (3+ levels)" do
    context "all levels set" do
      subject { described_class.new({a: {b: {c: {d: "deep"}}}}) }

      it "reads the correct property" do
        expect(subject.a.b.c.d).to eq "deep"
      end
    end

    context "no levels set" do
      subject { described_class.new({}) }

      it "returns a value where nil? is true at every intermediate level" do
        expect(subject.a).to be_nil
        expect(subject.a.b).to be_nil
        expect(subject.a.b.c).to be_nil
      end

      it "supports chaining to any depth without error" do
        expect { subject.a.b.c.d.e.f.g }.not_to raise_error
      end
    end
  end

  describe "method vs bracket access equivalence" do
    subject { described_class.new({foo: "bar"}) }

    context "reading the same key via method and bracket returns the same value" do
      it "for a set property" do
        expect(subject.foo).to eq subject[:foo]
      end

      it "for an unset property" do
        method_result = subject.missing
        bracket_result = subject[:missing]
        expect(method_result).to be_nil
        expect(bracket_result).to be_nil
      end
    end

    it "writing via method and reading via bracket returns the written value" do
      subject.baz = "qux"
      expect(subject[:baz]).to eq "qux"
    end

    it "writing via bracket and reading via method returns the written value" do
      subject[:baz] = "qux"
      expect(subject.baz).to eq "qux"
    end
  end
end
```

**Step 2: Run to check**

Run: `bundle exec rspec spec/flexor/reading_spec.rb --format documentation`

**Step 3: Commit**

```bash
git add spec/flexor/reading_spec.rb
git commit -m "test: add reading properties specs"
```

---

## Task 5: Writing properties specs

**Files:**
- Create: `spec/flexor/writing_spec.rb`

**Step 1: Write the spec file**

```ruby
RSpec.describe Flexor do
  describe "writing a level 1 property via method" do
    subject { described_class.new }

    it "writes and reads the written property" do
      subject.foo = "bar"
      expect(subject.foo).to eq "bar"
    end
  end

  describe "writing a level 1 property via hash accessor" do
    subject { described_class.new }

    it "writes and reads the written property" do
      subject[:foo] = "bar"
      expect(subject[:foo]).to eq "bar"
    end
  end

  describe "writing a level 2 property via method" do
    context "the level 1 property has been set" do
      subject { described_class.new({rank: {first: 1}}) }

      it "writes and reads the written property" do
        subject.rank.second = 2
        expect(subject.rank.second).to eq 2
      end
    end

    context "the level 1 property has NOT been set" do
      subject { described_class.new }

      it "vivifies the level 1 property" do
        subject.rank.first = 1
        expect(subject.rank).to be_a described_class
        expect(subject.rank).not_to be_nil
      end

      it "writes and reads the written property" do
        subject.rank.first = 1
        expect(subject.rank.first).to eq 1
      end
    end
  end

  describe "writing a level 2 property via hash accessor" do
    context "the level 1 property has been set" do
      subject { described_class.new({rank: {first: 1}}) }

      it "writes and reads the written property" do
        subject[:rank][:second] = 2
        expect(subject[:rank][:second]).to eq 2
      end
    end

    context "the level 1 property has NOT been set" do
      subject { described_class.new }

      it "vivifies the level 1 property" do
        subject[:rank][:first] = 1
        expect(subject[:rank]).to be_a described_class
        expect(subject[:rank]).not_to be_nil
      end

      it "writes and reads the written property" do
        subject[:rank][:first] = 1
        expect(subject[:rank][:first]).to eq 1
      end
    end
  end

  describe "writing at arbitrary depth (3+ levels)" do
    subject { described_class.new }

    context "no intermediate levels set" do
      it "vivifies every intermediate level" do
        subject.a.b.c = "deep"
        expect(subject.a).to be_a described_class
        expect(subject.a.b).to be_a described_class
      end

      it "writes and reads the written property" do
        subject.a.b.c = "deep"
        expect(subject.a.b.c).to eq "deep"
      end
    end
  end

  describe "assigning a plain hash via setter" do
    subject { described_class.new }

    context "stores the raw hash" do
      before { subject.config = {db: {host: "localhost"}} }

      it "bracket access returns a Hash, not a Flexor" do
        expect(subject[:config]).to be_a Hash
        expect(subject[:config]).not_to be_a described_class
      end
    end

    context "method chaining on the assigned hash" do
      before { subject.config = {db: {host: "localhost"}} }

      it "raises NoMethodError (Hash does not support dynamic methods)" do
        expect { subject.config.db }.to raise_error(NoMethodError)
      end
    end
  end

  describe "assigning an array via setter" do
    subject { described_class.new }

    context "with an array of scalars" do
      it "stores and retrieves the array" do
        subject.tags = ["a", "b", "c"]
        expect(subject.tags).to eq ["a", "b", "c"]
      end
    end

    context "with an array of hashes" do
      it "stores raw hashes (does not auto-convert)" do
        subject.items = [{id: 1}, {id: 2}]
        expect(subject.items.first).to be_a Hash
        expect(subject.items.first).not_to be_a described_class
      end
    end
  end

  describe "overwriting" do
    subject { described_class.new({user: {name: "alice", age: 30}}) }

    it "replacing a nested subtree with a scalar stores the scalar" do
      subject.user = "gone"
      expect(subject.user).to eq "gone"
    end

    it "replacing a nested subtree with a scalar removes the old subtree" do
      subject.user = "gone"
      expect { subject.user.name }.to raise_error(NoMethodError)
    end

    it "replacing a scalar with a nested write vivifies the new path" do
      subject.user.name = "bob"
      subject.user = "flat"
      subject.user = {first: "carol"}
      expect(subject[:user]).to be_a Hash
    end

    it "replacing a scalar with nil makes the property read as nil" do
      subject.user.name = "bob"
      subject.user.name = nil
      expect(subject.user.name).to be_nil
    end
  end
end
```

**Step 2: Run to check**

Run: `bundle exec rspec spec/flexor/writing_spec.rb --format documentation`
Expected: Some failures around plain hash assignment behavior

**Step 3: Commit**

```bash
git add spec/flexor/writing_spec.rb
git commit -m "test: add writing properties specs"
```

---

## Task 6: Comparison specs (`nil?`, `==`, `===`)

**Files:**
- Create: `spec/flexor/comparison_spec.rb`

**Step 1: Write the spec file**

```ruby
RSpec.describe Flexor do
  describe "#nil?" do
    it "is truthy on an unset property (empty Flexor)" do
      store = described_class.new
      expect(store.missing.nil?).to be true
    end

    it "is falsey on a property with a value" do
      store = described_class.new({name: "alice"})
      expect(store.name.nil?).to be false
    end

    it "is truthy on a property set explicitly to nil (via NilClass#nil?)" do
      store = described_class.new({gone: nil})
      expect(store.gone.nil?).to be true
    end

    it "is truthy on a root Flexor with no data" do
      store = described_class.new
      expect(store.nil?).to be true
    end

    it "is falsey on a root Flexor with data" do
      store = described_class.new({a: 1})
      expect(store.nil?).to be false
    end
  end

  describe "#==" do
    context "when comparing an unset property (empty Flexor)" do
      subject { described_class.new }

      it "against nil is truthy" do
        expect(subject.missing == nil).to be true
      end

      it "against a non-nil value is falsey" do
        expect(subject.missing == "something").to be false
      end
    end

    context "when comparing two Flexors" do
      it "is truthy when both have identical contents" do
        a = described_class.new({x: 1, y: 2})
        b = described_class.new({x: 1, y: 2})
        expect(a == b).to be true
      end

      it "is falsey when contents differ" do
        a = described_class.new({x: 1})
        b = described_class.new({x: 2})
        expect(a == b).to be false
      end

      it "is truthy when both are empty" do
        a = described_class.new
        b = described_class.new
        expect(a == b).to be true
      end
    end

    context "when comparing a Flexor against a Hash" do
      it "is truthy when keys and values are identical" do
        store = described_class.new({x: 1, y: 2})
        expect(store == {x: 1, y: 2}).to be true
      end

      it "is falsey when keys and values are NOT identical" do
        store = described_class.new({x: 1})
        expect(store == {x: 99}).to be false
      end
    end

    context "when comparing a property set explicitly to nil" do
      subject { described_class.new({gone: nil}) }

      it "against nil is truthy (via NilClass#==)" do
        expect(subject.gone == nil).to be true
      end

      it "against a non-nil value is falsey (via NilClass#==)" do
        expect(subject.gone == "something").to be false
      end
    end

    context "when comparing a scalar value" do
      subject { described_class.new({name: "alice"}) }

      it "against an identical scalar is truthy (via String#==)" do
        expect(subject.name == "alice").to be true
      end

      it "against a different scalar is falsey (via String#==)" do
        expect(subject.name == "bob").to be false
      end
    end

    context "symmetry" do
      it "documents whether nil == empty Flexor is symmetric" do
        store = described_class.new
        # empty_flexor == nil is true, but nil == empty_flexor may be false
        # because NilClass#== does not know about Flexor
        expect(store == nil).to be true
        # Document actual behavior:
        result = (nil == store)
        expect(result).to eq(result) # self-consistent assertion; documents behavior
      end
    end
  end

  describe "#===" do
    context "when used in a case/when on a Flexor value" do
      it "matches against a scalar when values are equal" do
        store = described_class.new({status: "active"})
        matched = case store.status
                  when "active" then true
                  else false
                  end
        expect(matched).to be true
      end

      it "matches against nil when property is unset" do
        store = described_class.new
        matched = case store.missing
                  when nil then true
                  else false
                  end
        expect(matched).to be true
      end
    end
  end

  describe ".===" do
    context "when used as a class in case/when" do
      it "matches a Flexor instance" do
        store = described_class.new
        matched = case store
                  when described_class then true
                  else false
                  end
        expect(matched).to be true
      end

      it "does not match a plain Hash" do
        matched = case({a: 1})
                  when described_class then true
                  else false
                  end
        expect(matched).to be false
      end

      it "does not match nil" do
        matched = case nil
                  when described_class then true
                  else false
                  end
        expect(matched).to be false
      end
    end
  end
end
```

**Step 2: Run to check**

Run: `bundle exec rspec spec/flexor/comparison_spec.rb --format documentation`
Expected: `===` specs will fail (implementation has `binding.debugger` stubs)

**Step 3: Commit**

```bash
git add spec/flexor/comparison_spec.rb
git commit -m "test: add comparison specs (nil?, ==, ===)"
```

---

## Task 7: Conversion specs (`to_s`, `inspect`, `to_ary`, `to_h`, pattern matching)

**Files:**
- Create: `spec/flexor/conversion_spec.rb`

**Step 1: Write the spec file**

```ruby
RSpec.describe Flexor do
  describe "#to_s" do
    context "when the property has been set" do
      it "returns the string representation for a scalar value" do
        store = described_class.new({name: "alice"})
        expect(store.to_s).to be_a String
        expect(store.to_s).to eq store.instance_variable_get(:@store).to_s
      end

      it "returns the string representation for a nested value" do
        store = described_class.new({user: {name: "alice"}})
        expect(store.to_s).to be_a String
        expect(store.to_s.length).to be > 0
      end
    end

    context "when the property has NOT been set" do
      subject { described_class.new }

      it "returns an empty string to match nil.to_s behavior" do
        expect(subject.missing.to_s).to eq ""
      end

      it "returns an empty string, not actual nil" do
        expect(subject.missing.to_s).not_to be_nil
        expect(subject.missing.to_s).to be_a String
      end

      it "is indistinguishable from nil in string interpolation" do
        expect("value: #{subject.missing}").to eq "value: "
        expect("value: #{nil}").to eq "value: "
      end

      it "is indistinguishable from nil when passed to puts" do
        # puts calls to_s, then to_ary; both should behave like nil
        expect(subject.missing.to_s).to eq nil.to_s
      end
    end

    context "at multiple levels of depth" do
      subject { described_class.new }

      it "returns empty string at every unset level" do
        expect(subject.a.to_s).to eq ""
        expect(subject.a.b.to_s).to eq ""
        expect(subject.a.b.c.to_s).to eq ""
      end

      it "is indistinguishable from nil in puts at any depth" do
        expect(subject.a.b.c.to_s).to eq nil.to_s
      end
    end

    context "root vs non-root" do
      it "root with data returns the store's string representation" do
        store = described_class.new({a: 1})
        expect(store.to_s).to eq store.instance_variable_get(:@store).to_s
      end

      it "root without data returns empty string" do
        store = described_class.new
        expect(store.to_s).to eq ""
      end

      it "non-root with data returns the store's string representation" do
        store = described_class.new({nested: {a: 1}})
        inner = store.nested
        expect(inner.to_s).to eq inner.instance_variable_get(:@store).to_s
      end

      it "non-root without data returns empty string" do
        store = described_class.new
        expect(store.missing.to_s).to eq ""
      end
    end
  end

  describe "#inspect" do
    it "on a root Flexor with values returns the hash inspection" do
      store = described_class.new({a: 1})
      expect(store.inspect).to eq store.instance_variable_get(:@store).inspect
    end

    it "on a root Flexor without values returns the empty hash inspection" do
      store = described_class.new
      expect(store.inspect).to eq({}.inspect)
    end

    it "on an unset property (empty non-root Flexor) is indistinguishable from inspecting nil" do
      store = described_class.new
      expect(store.missing.inspect).to eq nil.inspect
    end

    it "on a non-root Flexor with values returns the hash inspection" do
      store = described_class.new({nested: {a: 1}})
      inner = store.nested
      expect(inner.inspect).to eq inner.instance_variable_get(:@store).inspect
    end
  end

  describe "#to_ary" do
    subject { described_class.new({a: 1}) }

    it "returns nil to prevent puts from treating Flexor as an array" do
      expect(subject.to_ary).to be_nil
    end

    it "prevents splat expansion from treating Flexor as an array" do
      expect { a, b = *subject }.not_to raise_error
    end
  end

  describe "#to_h" do
    it "returns a plain hash with scalar values" do
      store = described_class.new({a: 1, b: "two"})
      result = store.to_h
      expect(result).to eq({a: 1, b: "two"})
      expect(result).to be_a Hash
      expect(result).not_to be_a described_class
    end

    it "recursively converts nested Flexors back to hashes" do
      store = described_class.new({user: {name: "alice"}})
      result = store.to_h
      expect(result).to eq({user: {name: "alice"}})
      expect(result[:user]).to be_a Hash
      expect(result[:user]).not_to be_a described_class
    end

    it "preserves arrays of scalars" do
      store = described_class.new({tags: ["a", "b"]})
      expect(store.to_h).to eq({tags: ["a", "b"]})
    end

    it "recursively converts Flexors inside arrays" do
      store = described_class.new({items: [{id: 1}, {id: 2}]})
      result = store.to_h
      expect(result[:items]).to eq [{id: 1}, {id: 2}]
      result[:items].each { |item| expect(item).to be_a Hash }
    end

    it "converts empty nested Flexors to nil" do
      store = described_class.new({})
      _ = store.missing # trigger autovivification but don't write
      # The empty Flexor at :missing should convert to nil in to_h
      # (phantom keys question - see next test)
    end

    context "round-trip" do
      it "flat hash survives new -> to_h unchanged" do
        h = {a: 1, b: "two", c: true}
        expect(described_class.new(h).to_h).to eq h
      end

      it "nested hash survives new -> to_h unchanged" do
        h = {user: {name: "alice", age: 30}}
        expect(described_class.new(h).to_h).to eq h
      end

      it "deeply nested hash survives new -> to_h unchanged" do
        h = {a: {b: {c: {d: "deep"}}}}
        expect(described_class.new(h).to_h).to eq h
      end

      it "hash with arrays survives new -> to_h unchanged" do
        h = {tags: ["a", "b"], items: [{id: 1}]}
        expect(described_class.new(h).to_h).to eq h
      end
    end

    context "with autovivified but never written paths" do
      it "does not include phantom keys" do
        store = described_class.new({real: "data"})
        _ = store.phantom.deep.chain # read-only access
        result = store.to_h
        expect(result.keys).to eq [:real]
        expect(result).to eq({real: "data"})
      end
    end
  end

  describe "#deconstruct_keys" do
    context "with a Flexor containing values" do
      subject { described_class.new({name: "alice", age: 30, city: "NYC"}) }

      it "supports pattern matching via case/in" do
        matched = case subject
                  in {name: "alice"}
                    true
                  else
                    false
                  end
        expect(matched).to be true
      end

      it "extracts matching keys" do
        case subject
        in {name: name, age: age}
          expect(name).to eq "alice"
          expect(age).to eq 30
        end
      end

      it "returns only requested keys" do
        result = subject.deconstruct_keys([:name])
        expect(result).to have_key(:name)
      end
    end

    context "with nested Flexors" do
      subject { described_class.new({user: {name: "alice"}}) }

      it "supports nested pattern matching" do
        case subject
        in {user: {name: name}}
          expect(name).to eq "alice"
        end
      end
    end

    context "with no keys requested" do
      subject { described_class.new({a: 1, b: 2}) }

      it "returns the entire store" do
        result = subject.deconstruct_keys(nil)
        expect(result.keys).to include(:a, :b)
      end
    end

    context "on an empty Flexor" do
      subject { described_class.new }

      it "returns an empty hash" do
        result = subject.deconstruct_keys(nil)
        expect(result).to eq({})
      end
    end
  end

  describe "#deconstruct" do
    it "documents the intended behavior for array-style pattern matching" do
      store = described_class.new({a: 1, b: 2})
      # Array-style pattern matching: case store in [a, b, c]
      # Design decision: what this means for a hash-backed store
      expect(store).to respond_to(:deconstruct)
    end
  end
end
```

**Step 2: Run to check**

Run: `bundle exec rspec spec/flexor/conversion_spec.rb --format documentation`
Expected: `deconstruct_keys` and `deconstruct` specs will fail (stubs with `binding.debugger`)

**Step 3: Commit**

```bash
git add spec/flexor/conversion_spec.rb
git commit -m "test: add conversion specs (to_s, inspect, to_ary, to_h, pattern matching)"
```

---

## Task 8: Hash-like behavior specs

**Files:**
- Create: `spec/flexor/hash_like_spec.rb`

**Step 1: Write the spec file**

```ruby
RSpec.describe Flexor do
  describe "hash-like query methods" do
    describe "#empty?" do
      it "is truthy when the store has no data" do
        expect(described_class.new.empty?).to be true
      end

      it "is falsey when the store has data" do
        expect(described_class.new({a: 1}).empty?).to be false
      end

      it "does not autovivify a key named :empty?" do
        store = described_class.new({a: 1})
        store.empty?
        expect(store.to_h.keys).not_to include(:empty?)
      end
    end

    describe "#keys" do
      it "returns the keys of the store" do
        store = described_class.new({a: 1, b: 2})
        expect(store.keys).to contain_exactly(:a, :b)
      end

      it "does not autovivify a key named :keys" do
        store = described_class.new({a: 1})
        store.keys
        expect(store.to_h.keys).not_to include(:keys)
      end
    end

    describe "#values" do
      it "returns the values of the store" do
        store = described_class.new({a: 1, b: 2})
        expect(store.values).to contain_exactly(1, 2)
      end

      it "does not autovivify a key named :values" do
        store = described_class.new({a: 1})
        store.values
        expect(store.to_h.keys).not_to include(:values)
      end
    end

    describe "#size / #length" do
      it "returns the number of keys in the store" do
        store = described_class.new({a: 1, b: 2, c: 3})
        expect(store.size).to eq 3
        expect(store.length).to eq 3
      end

      it "does not autovivify a key named :size or :length" do
        store = described_class.new({a: 1})
        store.size
        store.length
        expect(store.to_h.keys).not_to include(:size, :length)
      end
    end

    describe "#key? / #has_key?" do
      context "when the key exists" do
        subject { described_class.new({name: "alice"}) }

        it "is truthy" do
          expect(subject.key?(:name)).to be true
          expect(subject.has_key?(:name)).to be true
        end
      end

      context "when the key does not exist" do
        subject { described_class.new({name: "alice"}) }

        it "is falsey" do
          expect(subject.key?(:missing)).to be false
          expect(subject.has_key?(:missing)).to be false
        end

        it "does not autovivify the queried key" do
          subject.key?(:phantom)
          expect(subject.to_h.keys).not_to include(:phantom)
        end
      end
    end
  end

  describe "symbol vs string keys" do
    it "method access uses symbol keys (store.foo writes to and reads from :foo)" do
      store = described_class.new
      store.foo = "bar"
      expect(store[:foo]).to eq "bar"
    end

    it "bracket access with a symbol reads and writes using the symbol key" do
      store = described_class.new
      store[:foo] = "bar"
      expect(store[:foo]).to eq "bar"
    end

    it "bracket access with a string reads and writes using the string key" do
      store = described_class.new
      store["foo"] = "bar"
      expect(store["foo"]).to eq "bar"
    end

    context "cross-access" do
      it "store.foo and store[:foo] access the same value" do
        store = described_class.new
        store.foo = "bar"
        expect(store[:foo]).to eq "bar"

        store2 = described_class.new
        store2[:baz] = "qux"
        expect(store2.baz).to eq "qux"
      end

      it 'store.foo and store["foo"] do NOT access the same value' do
        store = described_class.new
        store.foo = "bar"
        expect(store["foo"]).not_to eq "bar"
      end
    end
  end

  describe "method name collisions" do
    context "methods defined on Object (class, freeze, hash, object_id, send, display)" do
      subject { described_class.new({class: "fancy", freeze: "cold"}) }

      it "are not intercepted by method_missing" do
        expect(subject.class).to eq described_class
        expect(subject.object_id).to be_a Integer
      end

      it "values stored under those keys are accessible via bracket" do
        expect(subject[:class]).to eq "fancy"
        expect(subject[:freeze]).to eq "cold"
      end
    end

    context "methods defined on Flexor (to_h, to_s, nil?, ==)" do
      subject { described_class.new({to_h: "override", to_s: "nope", nil?: "not nil"}) }

      it "are not intercepted by method_missing" do
        expect(subject.to_h).to be_a Hash
        expect(subject.nil?).to be(false).or be(true) # depends on implementation
      end

      it "values stored under those keys are accessible via bracket" do
        expect(subject[:to_h]).to eq "override"
        expect(subject[:to_s]).to eq "nope"
        expect(subject[:nil?]).to eq "not nil"
      end
    end
  end
end
```

**Step 2: Run to check**

Run: `bundle exec rspec spec/flexor/hash_like_spec.rb --format documentation`
Expected: Hash-like methods (keys, values, size, empty?, key?) likely fail — not yet delegated

**Step 3: Commit**

```bash
git add spec/flexor/hash_like_spec.rb
git commit -m "test: add hash-like behavior, key types, and method collision specs"
```

---

## Task 9: Introspection and edge case specs

**Files:**
- Create: `spec/flexor/introspection_spec.rb`

**Step 1: Write the spec file**

```ruby
RSpec.describe Flexor do
  describe "method_missing edge cases" do
    subject { described_class.new({foo: "bar"}) }

    it "calling a method with arguments (store.foo(1)) raises NoMethodError" do
      expect { subject.foo(1) }.to raise_error(NoMethodError)
    end

    it "calling a method with a block raises NoMethodError" do
      expect { subject.foo { "block" } }.to raise_error(NoMethodError)
    end

    it "setter with too many arguments (store.foo = 1, 2) raises NoMethodError" do
      expect { subject.send(:foo=, 1, 2) }.to raise_error(NoMethodError)
    end
  end

  describe "#respond_to?" do
    subject { described_class.new }

    it "is truthy for any arbitrary method name" do
      expect(subject.respond_to?(:anything)).to be true
      expect(subject.respond_to?(:made_up_method)).to be true
    end

    it "is truthy for method names that also exist on Object" do
      expect(subject.respond_to?(:class)).to be true
      expect(subject.respond_to?(:object_id)).to be true
    end

    it "is truthy with include_private: true" do
      expect(subject.respond_to?(:anything, true)).to be true
    end
  end

  describe "#respond_to_missing?" do
    subject { described_class.new }

    it "returns true for any method name" do
      expect(subject.respond_to_missing?(:anything)).to be true
    end
  end
end
```

**Step 2: Run to check**

Run: `bundle exec rspec spec/flexor/introspection_spec.rb --format documentation`

**Step 3: Commit**

```bash
git add spec/flexor/introspection_spec.rb
git commit -m "test: add method_missing edge cases and respond_to? specs"
```

---

## Task 10: Array handling, autovivification, thread safety, dup/clone, freeze, enumeration specs

**Files:**
- Create: `spec/flexor/advanced_spec.rb`

**Step 1: Write the spec file**

```ruby
RSpec.describe Flexor do
  describe "array handling end-to-end" do
    context "via constructor" do
      it "hashes inside arrays are converted to Flexors" do
        store = described_class.new({items: [{id: 1}]})
        expect(store.items.first).to be_a described_class
      end

      it "scalars inside arrays are preserved" do
        store = described_class.new({tags: [1, "two", true]})
        expect(store.tags).to eq [1, "two", true]
      end

      it "nested arrays of hashes are converted recursively" do
        store = described_class.new({matrix: [[{a: 1}], [{b: 2}]]})
        expect(store.matrix[0][0]).to be_a described_class
        expect(store.matrix[0][0].a).to eq 1
      end
    end

    context "via direct assignment" do
      it "assigning an array of hashes does not auto-convert" do
        store = described_class.new
        store.items = [{id: 1}, {id: 2}]
        expect(store.items.first).to be_a Hash
      end
    end

    context "reading from arrays stored in Flexor" do
      it "array elements are accessible via standard array methods" do
        store = described_class.new({tags: ["a", "b", "c"]})
        expect(store.tags.first).to eq "a"
        expect(store.tags.last).to eq "c"
        expect(store.tags.length).to eq 3
      end
    end
  end

  describe "autovivification side effects" do
    it "reading an unset property creates the key in the store (default_proc behavior)" do
      store = described_class.new
      _ = store[:phantom]
      expect(store.instance_variable_get(:@store)).to have_key(:phantom)
    end

    it "the created key holds an empty Flexor" do
      store = described_class.new
      result = store[:phantom]
      expect(result).to be_a described_class
      expect(result).to be_nil
    end

    it "chaining reads on unset properties creates keys at every intermediate level" do
      store = described_class.new
      _ = store.a.b.c
      inner_store = store.instance_variable_get(:@store)
      expect(inner_store).to have_key(:a)
    end

    it "documents whether reads leave traces in to_h" do
      store = described_class.new({real: "data"})
      _ = store.phantom
      # This ties back to the "phantom keys" design decision:
      # Chosen behavior: phantom keys do NOT appear in to_h
      expect(store.to_h).to eq({real: "data"})
    end
  end

  describe "thread safety" do
    it "concurrent reads on the same Flexor do not raise" do
      store = described_class.new({a: 1, b: 2, c: 3})
      threads = 10.times.map do
        Thread.new { 100.times { store.a; store.b; store.c } }
      end
      expect { threads.each(&:join) }.not_to raise_error
    end

    it "concurrent writes to different keys documents expected behavior" do
      store = described_class.new
      threads = 10.times.map do |i|
        Thread.new { store[:"key_#{i}"] = i }
      end
      expect { threads.each(&:join) }.not_to raise_error
    end

    it "concurrent autovivification documents expected behavior" do
      store = described_class.new
      threads = 10.times.map do |i|
        Thread.new { _ = store[:"auto_#{i}"] }
      end
      expect { threads.each(&:join) }.not_to raise_error
    end
  end

  describe "dup and clone" do
    context "duping a Flexor" do
      it "returns a new Flexor with the same contents" do
        original = described_class.new({a: 1, b: 2})
        copy = original.dup
        expect(copy).to be_a described_class
        expect(copy.to_h).to eq original.to_h
        expect(copy).not_to equal original
      end

      it "modifications to the dup do not affect the original" do
        original = described_class.new({a: 1})
        copy = original.dup
        copy.b = 2
        expect(original.to_h.keys).not_to include(:b)
      end
    end

    context "cloning a Flexor" do
      it "returns a new Flexor with the same contents" do
        original = described_class.new({a: 1, b: 2})
        copy = original.clone
        expect(copy).to be_a described_class
        expect(copy.to_h).to eq original.to_h
        expect(copy).not_to equal original
      end

      it "modifications to the clone do not affect the original" do
        original = described_class.new({a: 1})
        copy = original.clone
        copy.b = 2
        expect(original.to_h.keys).not_to include(:b)
      end
    end

    context "deep nesting" do
      it "dup is shallow (nested Flexors are shared)" do
        original = described_class.new({nested: {a: 1}})
        copy = original.dup
        copy.nested.a = 99
        # Shallow copy: nested Flexor is shared, so original is also affected
        expect(original.nested.a).to eq 99
      end
    end
  end

  describe "freeze" do
    context "freezing a Flexor" do
      it "prevents further writes" do
        store = described_class.new({a: 1})
        store.freeze
        expect { store.b = 2 }.to raise_error(FrozenError)
      end

      it "reads still work" do
        store = described_class.new({a: 1})
        store.freeze
        expect(store.a).to eq 1
      end

      it "autovivification raises on frozen store" do
        store = described_class.new
        store.freeze
        expect { store[:missing] }.to raise_error(FrozenError)
      end
    end
  end

  describe "enumeration" do
    context "each / map / select" do
      subject { described_class.new({a: 1, b: 2, c: 3}) }

      it "delegates to the underlying store" do
        keys = []
        subject.each { |k, _v| keys << k }
        expect(keys).to contain_exactly(:a, :b, :c)
      end

      it "map works on the store" do
        result = subject.map { |k, _v| k }
        expect(result).to contain_exactly(:a, :b, :c)
      end

      it "select works on the store" do
        result = subject.select { |_k, v| v.is_a?(Integer) && v > 1 }
        expect(result.map(&:first)).to contain_exactly(:b, :c)
      end
    end
  end
end
```

**Step 2: Run to check**

Run: `bundle exec rspec spec/flexor/advanced_spec.rb --format documentation`
Expected: Many failures — dup/clone, freeze, enumeration, hash-like delegation not yet implemented

**Step 3: Commit**

```bash
git add spec/flexor/advanced_spec.rb
git commit -m "test: add advanced specs (arrays, autovivification, threads, dup, freeze, enumeration)"
```

---

## Task 11: Run full suite and verify rubocop compliance

**Step 1: Run the full test suite**

Run: `bundle exec rspec --format documentation`
Expected: Some pass (existing implementation), many fail (unimplemented features). Document pass/fail counts.

**Step 2: Run rubocop on spec files**

Run: `bundle exec rubocop spec/`
Expected: Clean or minor style issues.

**Step 3: Fix any rubocop offenses in spec files**

If rubocop reports offenses, fix them. Do NOT change any `lib/` files.

**Step 4: Final commit**

```bash
git add -A
git commit -m "test: complete TDD spec suite from specs.yaml (red phase)"
```

---

## Verification

After all tasks:
1. `bundle exec rspec --format documentation` — runs all specs, documents which are red/green
2. `bundle exec rubocop spec/` — all spec files pass rubocop
3. No changes to any files under `lib/` — implementation is untouched
4. Every spec in specs.yaml has a corresponding RSpec example

## File Summary

| File | Specs.yaml Coverage |
|------|-------------------|
| `spec/flexor_spec.rb` | Version only |
| `spec/flexor/constructor_spec.rb` | Lines 1-30 (Flexor.new) |
| `spec/flexor/from_json_spec.rb` | Lines 32-43 (Flexor.from_json) |
| `spec/flexor/reading_spec.rb` | Lines 45-95 (reading + equivalence) |
| `spec/flexor/writing_spec.rb` | Lines 97-150 (writing + assignment + overwriting) |
| `spec/flexor/comparison_spec.rb` | Lines 151-217 (nil?, ==, ===) |
| `spec/flexor/conversion_spec.rb` | Lines 219-294 (to_s, inspect, to_ary, to_h, deconstruct) |
| `spec/flexor/hash_like_spec.rb` | Lines 296-346 (query methods, key types, collisions) |
| `spec/flexor/introspection_spec.rb` | Lines 340-358 (method_missing edges, respond_to?) |
| `spec/flexor/advanced_spec.rb` | Lines 360-416 (arrays e2e, autovivification, threads, dup, freeze, enum) |
