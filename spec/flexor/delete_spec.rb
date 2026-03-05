RSpec.describe Flexor do
  describe "#delete" do
    it "removes the key and returns the value" do
      store = described_class.new({ a: 1, b: 2 })
      result = store.delete(:a)
      expect(result).to eq 1
      expect(store.key?(:a)).to be false
    end

    it "returns nil for a missing key" do
      store = described_class.new({ a: 1 })
      result = store.delete(:missing)
      expect(result).to be_nil
    end

    it "removes nested Flexors" do
      store = described_class.new({ user: { name: "alice" } })
      store.delete(:user)
      expect(store.to_h).to eq({})
    end

    it "does not affect other keys" do
      store = described_class.new({ a: 1, b: 2, c: 3 })
      store.delete(:b)
      expect(store.to_h).to eq({ a: 1, c: 3 })
    end
  end
end
