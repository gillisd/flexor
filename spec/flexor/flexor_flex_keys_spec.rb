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
end
