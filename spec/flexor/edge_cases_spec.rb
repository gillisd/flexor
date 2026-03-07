RSpec.describe Flexor do
  describe "#has_key?" do
    it "works identically to key? for existing keys" do
      store = described_class.new({ name: "alice" })
      expect(store.send(:has_key?, :name)).to be true
    end

    it "works identically to key? for missing keys" do
      store = described_class.new({ name: "alice" })
      expect(store.send(:has_key?, :missing)).to be false
    end

    it "does not autovivify the queried key" do
      store = described_class.new
      store.send(:has_key?, :phantom)
      expect(store.to_h.keys).not_to include(:phantom)
    end
  end

  describe "non-standard key types" do
    context "with numeric keys" do
      it "stores and retrieves values with integer keys" do
        store = described_class.new
        store[0] = "zero"
        expect(store[0]).to eq "zero"
      end
    end

    context "with boolean keys" do
      it "stores and retrieves values with boolean keys" do
        store = described_class.new
        store[true] = "yes"
        expect(store[true]).to eq "yes"
      end
    end

    context "with empty string keys" do
      it "stores and retrieves values with empty string keys" do
        store = described_class.new
        store[""] = "blank"
        expect(store[""]).to eq "blank"
      end
    end
  end

  describe "error message clarity" do
    context "with constructor ArgumentError" do
      it "includes the actual class in the error message" do
        expect { described_class.new("string") }.to raise_error(
          ArgumentError, /String/
        )
      end
    end

    context "with NoMethodError from cached getter" do
      it "includes the method name after caching" do
        store = described_class.new({ foo: "bar" })
        store.foo # cache the getter
        expect { store.foo(1) }.to raise_error(NoMethodError, /foo/)
      end
    end

    context "with NoMethodError from method_missing" do
      it "includes the method name before caching" do
        store = described_class.new({ foo: "bar" })
        expect { store.foo(1) }.to raise_error(NoMethodError, /foo/)
      end
    end
  end

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
