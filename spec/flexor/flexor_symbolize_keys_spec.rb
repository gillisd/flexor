RSpec.describe Flexor do
  describe "symbolize_keys construction" do
    context "with all string keys" do
      subject { described_class.new({ "foo" => "bar", "baz" => 42 }) }

      it "allows method access on string-keyed input" do
        expect(subject.foo).to eq "bar"
      end

      it "allows symbol bracket access on string-keyed input" do
        expect(subject[:baz]).to eq 42
      end
    end

    context "with Flexor[] shorthand" do
      it "creates a store from a string-keyed hash" do
        store = described_class[{ "baz" => 42 }]
        expect(store.baz).to eq 42
      end
    end

    context "with mixed string and symbol keys" do
      subject { described_class.new({ "foo" => "from_string", bar: "from_symbol" }) }

      it "accesses string-originated key via method" do
        expect(subject.foo).to eq "from_string"
      end

      it "accesses symbol-originated key via method" do
        expect(subject.bar).to eq "from_symbol"
      end

      it "produces symbol-only keys in to_h" do
        expect(subject.to_h).to eq({ foo: "from_string", bar: "from_symbol" })
      end
    end

    context "with nested string-keyed hashes" do
      subject { described_class.new({ "user" => { "name" => "alice", "age" => 30 } }) }

      it "allows chained method access through nested string keys" do
        expect(subject.user.name).to eq "alice"
        expect(subject.user.age).to eq 30
      end

      it "allows chained bracket access through nested string keys" do
        expect(subject[:user][:name]).to eq "alice"
      end
    end

    context "with arrays containing string-keyed hashes" do
      subject { described_class.new({ "items" => [{ "id" => 1 }, { "id" => 2 }] }) }

      it "converts string keys inside array elements" do
        expect(subject.items.first.id).to eq 1
        expect(subject.items.last.id).to eq 2
      end
    end
  end

  describe "symbolize_keys writing" do
    it "symbolizes string key on bracket write" do
      store = described_class.new
      store["color"] = "blue"
      expect(store.color).to eq "blue"
      expect(store.keys).to eq [:color]
    end

    it "updates existing key via string-keyed merge" do
      store = described_class.new({ name: "alice" })
      store.merge!({ "name" => "bob", "age" => 25 })
      expect(store.name).to eq "bob"
      expect(store.age).to eq 25
    end

    it "keeps all keys as symbols after merge" do
      store = described_class.new({ name: "alice" })
      store.merge!({ "name" => "bob", "age" => 25 })
      expect(store.keys).to eq [:name, :age]
    end

    context "with nested string-keyed hash (deep merge)" do
      subject { described_class.new({ user: { name: "alice" } }) }

      it "preserves existing nested values" do
        subject.merge!({ "user" => { "age" => 30 } })
        expect(subject.user.name).to eq "alice"
        expect(subject.user.age).to eq 30
      end

      it "does not create a duplicate key" do
        subject.merge!({ "user" => { "age" => 30 } })
        expect(subject.keys).to eq [:user]
      end
    end
  end

  describe "symbolize_keys to_h" do
    subject { described_class.new({ "foo" => "bar", "baz" => 42 }) }

    it "returns symbol keys after string-key ingestion" do
      expect(subject.to_h).to eq({ foo: "bar", baz: 42 })
    end
  end

  describe "symbolize_keys edge cases" do
    context "with non-string keys" do
      subject { described_class.new({ 0 => "zero", true => "yes" }) }

      it "preserves integer keys" do
        expect(subject[0]).to eq "zero"
      end

      it "preserves boolean keys" do
        expect(subject[true]).to eq "yes"
      end
    end

    context "with empty string key" do
      subject { described_class.new({ "" => "blank" }) }

      it "converts empty string to empty symbol" do
        expect(subject[:""]).to eq "blank"
      end
    end
  end

  describe "symbolize_keys + flex_keys interaction" do
    context "with string camelCase key" do
      subject { described_class.new({ "fooBar" => "baz" }) }

      it "resolves via method with snake_case" do
        expect(subject.foo_bar).to eq "baz"
      end

      it "resolves via symbol bracket with snake_case" do
        expect(subject[:foo_bar]).to eq "baz"
      end

      it "resolves via symbol bracket with exact camelCase" do
        expect(subject[:fooBar]).to eq "baz"
      end
    end
  end

  describe "symbolize_keys serialization" do
    it "preserves symbolized keys after Marshal round-trip" do
      store = described_class.new({ "foo" => "bar" })
      restored = Marshal.load(Marshal.dump(store))
      expect(restored.foo).to eq "bar"
    end
  end

  describe "symbolize_keys on frozen store" do
    subject do
      store = described_class.new({ "foo" => "bar" })
      store.freeze
      store
    end

    it "reads via symbol key" do
      expect(subject[:foo]).to eq "bar"
    end

    it "reads via method" do
      expect(subject.foo).to eq "bar"
    end
  end
end
