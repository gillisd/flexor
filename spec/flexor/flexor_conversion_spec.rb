RSpec.describe Flexor do
  describe "#to_s" do
    context "when the property has been set" do
      it "returns the string representation for a scalar value" do
        store = described_class.new({ name: "alice" })
        expect(store.to_s).to be_a String
        expect(store.to_s).to eq store.instance_variable_get(:@store).to_s
      end

      it "returns the string representation for a nested value" do
        store = described_class.new({ user: { name: "alice" } })
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
        nil_value = nil
        expect("value: #{subject.missing}").to eq "value: #{nil_value}"
      end

      it "is indistinguishable from nil when passed to puts" do
        expect(subject.missing.to_s).to eq nil.to_s
      end
    end

    context "with multiple levels of depth" do
      subject { described_class.new }

      it "returns empty string at level 1" do
        expect(subject.a.to_s).to eq ""
      end

      it "returns empty string at level 2" do
        expect(subject.a.b.to_s).to eq ""
      end

      it "returns empty string at level 3" do
        expect(subject.a.b.c.to_s).to eq ""
      end

      it "is indistinguishable from nil in puts at any depth" do
        expect(subject.a.b.c.to_s).to eq nil.to_s
      end
    end

    context "when comparing root vs non-root" do
      it "root with data returns the store's string representation" do
        store = described_class.new({ a: 1 })
        expect(store.to_s).to eq store.instance_variable_get(:@store).to_s
      end

      it "root without data returns empty string" do
        store = described_class.new
        expect(store.to_s).to eq ""
      end

      it "non-root with data returns the store's string representation" do
        store = described_class.new({ nested: { a: 1 } })
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
      store = described_class.new({ a: 1 })
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
      store = described_class.new({ nested: { a: 1 } })
      inner = store.nested
      expect(inner.inspect).to eq inner.instance_variable_get(:@store).inspect
    end
  end

  describe "#to_ary" do
    subject { described_class.new({ a: 1 }) }

    it "returns nil to prevent puts from treating Flexor as an array" do
      expect(subject.to_ary).to be_nil
    end

    it "prevents splat expansion from treating Flexor as an array" do
      arr = [subject, "other"]
      first, second = *arr
      expect(first).to be_a described_class
      expect(second).to eq "other"
    end
  end

  describe "#to_h" do
    it "returns the expected data" do
      store = described_class.new({ a: 1, b: "two" })
      expect(store.to_h).to eq({ a: 1, b: "two" })
    end

    it "returns a plain Hash" do
      store = described_class.new({ a: 1, b: "two" })
      expect(store.to_h).to be_a Hash
    end

    it "does not return a Flexor from to_h" do
      store = described_class.new({ a: 1, b: "two" })
      expect(store.to_h).not_to be_a described_class
    end

    it "recursively converts nested Flexors with correct data" do
      store = described_class.new({ user: { name: "alice" } })
      expect(store.to_h).to eq({ user: { name: "alice" } })
    end

    it "recursively converts nested Flexors to plain Hashes" do
      store = described_class.new({ user: { name: "alice" } })
      expect(store.to_h[:user]).to be_a Hash
    end

    it "nested values from to_h are not Flexors" do
      store = described_class.new({ user: { name: "alice" } })
      result = store.to_h
      expect(result[:user]).not_to be_a described_class
    end

    it "preserves arrays of scalars" do
      store = described_class.new({ tags: ["a", "b"] })
      expect(store.to_h).to eq({ tags: ["a", "b"] })
    end

    it "recursively converts Flexors inside arrays" do
      store = described_class.new({ items: [{ id: 1 }, { id: 2 }] })
      result = store.to_h
      expect(result[:items]).to eq [{ id: 1 }, { id: 2 }]
      expect(result[:items]).to all(be_a Hash)
    end

    it "converts empty nested Flexors to nil" do
      store = described_class.new({ empty_nested: {} })
      result = store.to_h
      expect(result[:empty_nested]).to be_nil
    end

    context "with round-trip conversion" do
      it "flat hash survives new -> to_h unchanged" do
        h = { a: 1, b: "two", c: true }
        expect(described_class.new(h).to_h).to eq h
      end

      it "nested hash survives new -> to_h unchanged" do
        h = { user: { name: "alice", age: 30 } }
        expect(described_class.new(h).to_h).to eq h
      end

      it "deeply nested hash survives new -> to_h unchanged" do
        h = { a: { b: { c: { d: "deep" } } } }
        expect(described_class.new(h).to_h).to eq h
      end

      it "hash with arrays survives new -> to_h unchanged" do
        h = { tags: ["a", "b"], items: [{ id: 1 }] }
        expect(described_class.new(h).to_h).to eq h
      end
    end

    context "with autovivified but never written paths" do
      it "does not include phantom keys" do
        store = described_class.new({ real: "data" })
        _ = store.phantom.deep.chain
        result = store.to_h
        expect(result.keys).to eq [:real]
        expect(result).to eq({ real: "data" })
      end
    end
  end

  describe "#deconstruct_keys" do
    context "with a Flexor containing values" do
      subject { described_class.new({ name: "alice", age: 30, city: "NYC" }) }

      it "supports pattern matching via case/in" do
        matched = case subject
                  in { name: "alice" } then true
                  else false
                  end
        expect(matched).to be true
      end

      it "extracts matching keys" do
        case subject
        in { name: name, age: age }
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
      subject { described_class.new({ user: { name: "alice" } }) }

      it "supports nested pattern matching" do
        case subject
        in { user: { name: name } }
          expect(name).to eq "alice"
        end
      end
    end

    context "with no keys requested" do
      subject { described_class.new({ a: 1, b: 2 }) }

      it "returns the entire store" do
        result = subject.deconstruct_keys(nil)
        expect(result.keys).to include(:a, :b)
      end
    end

    context "with an empty Flexor" do
      subject { described_class.new }

      it "returns an empty hash" do
        result = subject.deconstruct_keys(nil)
        expect(result).to eq({})
      end
    end
  end

  describe "#deconstruct" do
    it "returns the values of the store for array-style pattern matching" do
      store = described_class.new({ x: 1, y: -2 })
      matched = (store in [Integer, Integer])
      expect(matched).to be true
    end

    it "supports variable binding in array patterns" do
      store = described_class.new({ x: 1, y: -2 })
      store => [x, y]
      expect(x).to eq 1
      expect(y).to eq(-2)
    end

    it "returns an empty array for an empty Flexor" do
      store = described_class.new
      expect(store.deconstruct).to eq []
    end

    it "preserves nested Flexors for recursive pattern matching" do
      store = described_class.new({ point: { x: 1, y: 2 } })
      values = store.deconstruct
      expect(values.first).to be_a described_class
    end
  end
end
