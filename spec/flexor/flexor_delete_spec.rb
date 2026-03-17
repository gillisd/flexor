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

  describe "#clear" do
    it "removes all keys" do
      store = described_class.new({ a: 1, b: 2, c: 3 })
      store.clear
      expect(store.to_h).to eq({})
    end

    it "returns self" do
      store = described_class.new({ a: 1 })
      expect(store.clear).to equal store
    end

    it "makes the store nil-like" do
      store = described_class.new({ a: 1 })
      store.clear
      expect(store).to be_nil
      expect(store).to be_empty
    end

    it "allows new data after clearing" do
      store = described_class.new({ old: "data" })
      store.clear
      store.new_key = "fresh"
      expect(store.new_key).to eq "fresh"
      expect(store.key?(:old)).to be false
    end
  end
end
