RSpec.describe Flexor do
  describe "flex_keys reading" do
    describe "via method" do
      it "resolves snake_case to camelCase key" do
        store = described_class.new({ fooBar: "baz" })
        expect(store.foo_bar).to eq "baz"
      end

      it "resolves camelCase to snake_case key" do
        store = described_class.new({ foo_bar: "baz" })
        expect(store.fooBar).to eq "baz"
      end
    end

    describe "via bracket" do
      it "resolves snake_case to camelCase key" do
        store = described_class.new({ fooBar: "baz" })
        expect(store[:foo_bar]).to eq "baz"
      end

      it "resolves camelCase to snake_case key" do
        store = described_class.new({ foo_bar: "baz" })
        expect(store[:fooBar]).to eq "baz"
      end
    end

    describe "exact match priority" do
      it "prefers exact key when both exist" do
        store = described_class.new({ foo_bar: "exact", fooBar: "alternate" })
        expect(store[:foo_bar]).to eq "exact"
      end
    end

    describe "non-symbol keys" do
      it "resolves string keys via symbolize_keys + flex_keys" do
        store = described_class.new({ fooBar: "baz" })
        expect(store["foo_bar"]).to eq "baz"
      end
    end
  end

  describe "flex_keys writing" do
    describe "via bracket" do
      it "updates existing camelCase key when writing snake_case" do
        store = described_class.new({ fooBar: "old" })
        store[:foo_bar] = "new"
        expect(store[:fooBar]).to eq "new"
      end

      it "does not create a duplicate snake_case key" do
        store = described_class.new({ fooBar: "old" })
        store[:foo_bar] = "new"
        expect(store.keys).to eq [:fooBar]
      end
    end

    describe "via method" do
      it "updates existing camelCase key when writing snake_case" do
        store = described_class.new({ fooBar: "old" })
        store.foo_bar = "new"
        expect(store[:fooBar]).to eq "new"
      end
    end

    describe "#set_raw" do
      it "resolves key but skips vivification" do
        store = described_class.new({ fooBar: {} })
        store.set_raw(:foo_bar, { nested: true })
        expect(store[:fooBar]).to be_a Hash
      end
    end

    describe "#delete" do
      it "deletes via alternate key" do
        store = described_class.new({ fooBar: "baz" })
        store.delete(:foo_bar)
        expect(store.key?(:fooBar)).to be false
      end
    end
  end

  describe "flex_keys key?" do
    it "resolves alternate key" do
      store = described_class.new({ fooBar: "baz" })
      expect(store.key?(:foo_bar)).to be true
    end

    it "returns false when neither exact nor alternate exists" do
      store = described_class.new({ fooBar: "baz" })
      expect(store.key?(:missing)).to be false
    end
  end

  describe "flex_keys pattern matching" do
    it "resolves keys in deconstruct_keys" do
      store = described_class.new({ fooBar: "baz" })
      case store
      in { foo_bar: value }
        expect(value).to eq "baz"
      end
    end

    it "returns raw store when keys is nil" do
      store = described_class.new({ fooBar: "baz" })
      expect(store.deconstruct_keys(nil)).to have_key(:fooBar)
    end
  end

  describe "flex_keys propagation" do
    it "nested Flexors inherit flex_keys" do
      store = described_class.new({ user: { firstName: "Alice" } })
      expect(store.user.first_name).to eq "Alice"
    end

    it "arrays of hashes inherit flex_keys" do
      store = described_class.new({ items: [{ fooBar: 1 }] })
      expect(store.items.first.foo_bar).to eq 1
    end
  end

  describe "flex_keys serialization" do
    describe "Marshal round-trip" do
      it "preserves flex_keys after round-trip" do
        store = described_class.new({ fooBar: "baz" })
        restored = Marshal.load(Marshal.dump(store))
        expect(restored.foo_bar).to eq "baz"
      end
    end

    describe "YAML round-trip" do
      before { require "yaml" }

      it "preserves flex_keys after round-trip" do
        store = described_class.new({ fooBar: "baz" })
        yaml = YAML.dump(store)
        restored = YAML.safe_load(yaml, permitted_classes: [described_class, Symbol])
        expect(restored.foo_bar).to eq "baz"
      end
    end
  end

  describe "method caching with case resolution" do
    it "cached method getter still resolves alternate case on subsequent reads (camel stored, snake accessed)" do
      store = described_class.new({ fooBar: "baz" })
      store.foo_bar
      expect(store.foo_bar).to eq "baz"
    end

    it "cached method getter still resolves alternate case on subsequent reads (snake stored, camel accessed)" do
      store = described_class.new({ foo_bar: "qux" })
      store.fooBar
      expect(store.fooBar).to eq "qux"
    end

    it "invalidates the cached camelCase getter when its snake_case storage key is deleted" do
      store = described_class.new({ user_name: { nickname: "alice" } })
      store.userName.nickname
      store.delete(:user_name)
      store.userName.nickname = "bob"
      expect(store.userName.nickname).to eq("bob")
    end
  end

  describe "flex_keys edge cases" do
    it "merge! resolves keys" do
      store = described_class.new({ fooBar: "old" })
      store.merge!(foo_bar: "new")
      expect(store[:fooBar]).to eq "new"
    end

    it "merge preserves flex_keys through dup" do
      store = described_class.new({ fooBar: "old" })
      merged = store.merge(bazQux: "new")
      expect(merged.foo_bar).to eq "old"
    end

    it "has_key? resolves alternate keys" do
      store = described_class.new({ fooBar: "baz" })
      expect(store.send(:has_key?, :foo_bar)).to be true
    end

    it "dup preserves flex_keys" do
      store = described_class.new({ fooBar: "baz" })
      expect(store.dup.foo_bar).to eq "baz"
    end

    it "clone preserves flex_keys" do
      store = described_class.new({ fooBar: "baz" })
      expect(store.clone.foo_bar).to eq "baz"
    end

    it "resolves keys on a frozen store" do
      store = described_class.new({ fooBar: "baz" })
      store.freeze
      expect(store.foo_bar).to eq "baz"
    end
  end
end
