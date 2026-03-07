RSpec.describe Flexor do
  describe "serialization beyond JSON" do
    context "with Marshal" do
      it "round-trips via Marshal.dump and Marshal.load" do
        pending "Flexor needs marshal_dump/marshal_load"
        store = described_class.new({ a: 1, b: { c: 2 } })
        restored = Marshal.load(Marshal.dump(store))
        expect(restored.to_h).to eq({ a: 1, b: { c: 2 } })
      end

      it "preserves autovivification after Marshal round-trip" do
        pending "Flexor needs marshal_dump/marshal_load"
        store = described_class.new({ a: 1 })
        restored = Marshal.load(Marshal.dump(store))
        expect(restored.missing).to be_nil
        expect(restored.missing).to be_a described_class
      end
    end

    context "with YAML" do
      it "round-trips via YAML.dump and YAML.safe_load" do
        pending "Flexor needs encode_with/init_with"
        require "yaml"
        store = described_class.new({ a: 1, b: { c: 2 } })
        restored = YAML.safe_load(YAML.dump(store), permitted_classes: [described_class])
        expect(restored.to_h).to eq({ a: 1, b: { c: 2 } })
      end
    end
  end
end
