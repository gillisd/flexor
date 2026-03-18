RSpec.describe Flexor do
  describe "flex_keys reading" do
    describe "via method" do
      it "resolves snake_case to camelCase key" do
        store = described_class.new({ fooBar: "baz" }, flex_keys: true)
        expect(store.foo_bar).to eq "baz"
      end

      it "resolves camelCase to snake_case key" do
        store = described_class.new({ foo_bar: "baz" }, flex_keys: true)
        expect(store.fooBar).to eq "baz"
      end
    end

    describe "via bracket" do
      it "resolves snake_case to camelCase key" do
        store = described_class.new({ fooBar: "baz" }, flex_keys: true)
        expect(store[:foo_bar]).to eq "baz"
      end

      it "resolves camelCase to snake_case key" do
        store = described_class.new({ foo_bar: "baz" }, flex_keys: true)
        expect(store[:fooBar]).to eq "baz"
      end
    end

    describe "exact match priority" do
      it "prefers exact key when both exist" do
        store = described_class.new(
          { foo_bar: "exact", fooBar: "alternate" },
          flex_keys: true,
        )
        expect(store[:foo_bar]).to eq "exact"
      end
    end

    describe "when flex_keys is disabled" do
      it "does not resolve alternate keys" do
        store = described_class.new({ fooBar: "baz" }, flex_keys: false)
        expect(store.foo_bar).to be_nil
      end
    end

    describe "non-symbol keys" do
      it "does not resolve string keys" do
        store = described_class.new({ fooBar: "baz" }, flex_keys: true)
        expect(store["foo_bar"]).to be_nil
      end
    end
  end

  describe "flex_keys factory methods" do
    describe ".[] with Hash" do
      it "passes flex_keys to constructor" do
        store = described_class[{ fooBar: "baz" }, flex_keys: true]
        expect(store.foo_bar).to eq "baz"
      end
    end

    describe ".[] with JSON string" do
      it "passes flex_keys through from_json" do
        store = described_class['{"firstName":"Alice"}', flex_keys: true]
        expect(store.first_name).to eq "Alice"
      end
    end

    describe "F[] alias" do
      it "passes flex_keys" do
        store = F['{"firstName":"Alice"}', flex_keys: true]
        expect(store.first_name).to eq "Alice"
      end
    end

    describe ".from_json" do
      it "accepts flex_keys keyword" do
        store = described_class.from_json('{"firstName":"Alice"}', flex_keys: true)
        expect(store.first_name).to eq "Alice"
      end
    end
  end

  describe "flex_keys propagation" do
    it "nested Flexors inherit flex_keys from constructor" do
      store = described_class.new({ user: { firstName: "Alice" } }, flex_keys: true)
      expect(store.user.first_name).to eq "Alice"
    end

    it "autovivified children inherit flex_keys" do
      store = described_class.new({}, flex_keys: true)
      store.user.firstName = "Alice"
      expect(store.user.first_name).to eq "Alice"
    end

    it "arrays of hashes inherit flex_keys" do
      store = described_class.new({ items: [{ fooBar: 1 }] }, flex_keys: true)
      expect(store.items.first.foo_bar).to eq 1
    end
  end

  describe "flex_keys writing" do
    describe "via bracket" do
      it "updates existing camelCase key when writing snake_case" do
        store = described_class.new({ fooBar: "old" }, flex_keys: true)
        store[:foo_bar] = "new"
        expect(store[:fooBar]).to eq "new"
      end

      it "does not create a duplicate snake_case key" do
        store = described_class.new({ fooBar: "old" }, flex_keys: true)
        store[:foo_bar] = "new"
        expect(store.keys).to eq [:fooBar]
      end
    end

    describe "via method" do
      it "updates existing camelCase key when writing snake_case" do
        store = described_class.new({ fooBar: "old" }, flex_keys: true)
        store.foo_bar = "new"
        expect(store[:fooBar]).to eq "new"
      end
    end

    describe "#set_raw" do
      it "resolves key but skips vivification" do
        store = described_class.new({ fooBar: {} }, flex_keys: true)
        store.set_raw(:foo_bar, { nested: true })
        expect(store[:fooBar]).to be_a Hash
      end
    end

    describe "#delete" do
      it "deletes via alternate key" do
        store = described_class.new({ fooBar: "baz" }, flex_keys: true)
        store.delete(:foo_bar)
        expect(store.key?(:fooBar)).to be false
      end
    end
  end

  describe "flex_keys key?" do
    it "resolves alternate key" do
      store = described_class.new({ fooBar: "baz" }, flex_keys: true)
      expect(store.key?(:foo_bar)).to be true
    end

    it "returns false when neither exact nor alternate exists" do
      store = described_class.new({ fooBar: "baz" }, flex_keys: true)
      expect(store.key?(:missing)).to be false
    end
  end

  describe "flex_keys serialization" do
    describe "Marshal round-trip" do
      it "preserves flex_keys after Marshal round-trip" do
        store = described_class.new({ fooBar: "baz" }, flex_keys: true)
        restored = Marshal.load(Marshal.dump(store))
        expect(restored.foo_bar).to eq "baz"
      end
    end

    describe "YAML round-trip" do
      it "preserves flex_keys after YAML round-trip" do
        require "yaml"
        store = described_class.new({ fooBar: "baz" }, flex_keys: true)
        restored = YAML.safe_load(
          YAML.dump(store),
          permitted_classes: [described_class, Symbol],
        )
        expect(restored.foo_bar).to eq "baz"
      end
    end
  end
end
