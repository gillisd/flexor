RSpec.describe Flexor do
  describe "serialization beyond JSON" do
    context "with Marshal" do
      it "round-trips via Marshal.dump and Marshal.load" do
        store = described_class.new({ a: 1, b: { c: 2 } })
        restored = Marshal.load(Marshal.dump(store))
        expect(restored.to_h).to eq({ a: 1, b: { c: 2 } })
      end

      it "preserves autovivification after Marshal round-trip" do
        store = described_class.new({ a: 1 })
        restored = Marshal.load(Marshal.dump(store))
        expect(restored.missing).to be_nil
        expect(restored.missing).to be_a described_class
      end

      it "preserves nested Flexor structure after round-trip" do
        store = described_class.new({ user: { name: "alice" } })
        restored = Marshal.load(Marshal.dump(store))
        expect(restored.user).to be_a described_class
        expect(restored.user.name).to eq "alice"
      end

      it "preserves the root flag after round-trip" do
        store = described_class.new({ a: 1 })
        restored = Marshal.load(Marshal.dump(store))
        expect(restored.inspect).to eq store.inspect
      end
    end

    context "with YAML" do
      let(:permitted) { [described_class, Symbol] }

      it "round-trips via YAML.dump and YAML.safe_load" do
        require "yaml"
        store = described_class.new({ a: 1, b: { c: 2 } })
        restored = YAML.safe_load(YAML.dump(store), permitted_classes: permitted)
        expect(restored.to_h).to eq({ a: 1, b: { c: 2 } })
      end

      it "preserves autovivification after YAML round-trip" do
        require "yaml"
        store = described_class.new({ a: 1 })
        restored = YAML.safe_load(YAML.dump(store), permitted_classes: permitted)
        expect(restored.missing).to be_nil
        expect(restored.missing).to be_a described_class
      end

      it "preserves nested Flexor structure after round-trip" do
        require "yaml"
        store = described_class.new({ user: { name: "alice" } })
        restored = YAML.safe_load(YAML.dump(store), permitted_classes: permitted)
        expect(restored.user).to be_a described_class
        expect(restored.user.name).to eq "alice"
      end
    end
  end
end
