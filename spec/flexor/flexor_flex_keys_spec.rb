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
end
