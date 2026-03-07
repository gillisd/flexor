RSpec.describe Flexor do
  describe "#merge!" do
    context "with nil values" do
      it "nil overwrites an existing scalar" do
        store = described_class.new({ name: "alice" })
        store.merge!({ name: nil })
        expect(store[:name]).to equal(nil)
      end

      it "nil overwrites an existing nested Flexor" do
        store = described_class.new({ user: { name: "alice" } })
        store.merge!({ user: nil })
        expect(store[:user]).to equal(nil)
      end

      it "nil inside a nested hash is preserved during deep merge" do
        store = described_class.new({ db: { host: "localhost", port: 5432 } })
        store.merge!({ db: { port: nil } })
        expect(store.db.host).to eq "localhost"
        expect(store.db[:port]).to equal(nil)
      end
    end
  end

  describe "#merge" do
    context "with nil values" do
      it "nil overwrites an existing scalar in the new Flexor" do
        store = described_class.new({ name: "alice" })
        result = store.merge({ name: nil })
        expect(result[:name]).to equal(nil)
        expect(store.name).to eq "alice"
      end

      it "nil inside a nested hash is preserved during deep merge" do
        store = described_class.new({ db: { host: "localhost", port: 5432 } })
        result = store.merge({ db: { port: nil } })
        expect(result.db.host).to eq "localhost"
        expect(result.db[:port]).to equal(nil)
      end
    end
  end
end
