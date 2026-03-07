RSpec.describe Flexor do
  describe "#set_raw" do
    context "with method access on a raw hash" do
      it "method access on a raw Hash value returns the Hash (not a Flexor)" do
        store = described_class.new
        store.set_raw(:config, { db: "pg" })
        expect(store.config).to be_a Hash
        expect(store.config).not_to be_a described_class
      end
    end

    context "with interaction with method cache" do
      it "cached getter still returns the raw Hash" do
        store = described_class.new
        store.set_raw(:config, { db: "pg" })
        store.config # trigger caching
        expect(store.config).to be_a Hash
      end
    end
  end
end
