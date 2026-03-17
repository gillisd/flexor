RSpec.describe Flexor do
  describe "hash-like query methods" do
    describe "#empty?" do
      it "is truthy when the store has no data" do
        expect(described_class.new.empty?).to be true
      end

      it "is falsey when the store has data" do
        expect(described_class.new({ a: 1 }).empty?).to be false
      end

      it "does not autovivify a key named :empty?" do
        store = described_class.new({ a: 1 })
        store.empty?
        expect(store.to_h.keys).not_to include(:empty?)
      end
    end

    describe "#keys" do
      it "returns the keys of the store" do
        store = described_class.new({ a: 1, b: 2 })
        expect(store.keys).to contain_exactly(:a, :b)
      end

      it "does not autovivify a key named :keys" do
        store = described_class.new({ a: 1 })
        store.keys
        expect(store.to_h.keys).not_to include(:keys)
      end
    end

    describe "#values" do
      it "returns the values of the store" do
        store = described_class.new({ a: 1, b: 2 })
        expect(store.values).to contain_exactly(1, 2)
      end

      it "does not autovivify a key named :values" do
        store = described_class.new({ a: 1 })
        store.values
        expect(store.to_h.keys).not_to include(:values)
      end
    end

    describe "#size / #length" do
      it "returns the number of keys in the store" do
        store = described_class.new({ a: 1, b: 2, c: 3 })
        expect(store.size).to eq 3
        expect(store.length).to eq 3
      end

      it "does not autovivify a key named :size or :length" do
        store = described_class.new({ a: 1 })
        store.size
        store.length
        expect(store.to_h.keys).not_to include(:size, :length)
      end
    end

    describe "#key? / #has_key?" do
      context "when the key exists" do
        subject { described_class.new({ name: "alice" }) }

        it "is truthy" do
          expect(subject.key?(:name)).to be true
          expect(subject.key?(:name)).to be true
        end
      end

      context "when the key does not exist" do
        subject { described_class.new({ name: "alice" }) }

        it "is falsey" do
          expect(subject.key?(:missing)).to be false
          expect(subject.key?(:missing)).to be false
        end

        it "does not autovivify the queried key" do
          subject.key?(:phantom)
          expect(subject.to_h.keys).not_to include(:phantom)
        end
      end
    end
  end

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

  describe "symbol vs string keys" do
    it "method access uses symbol keys (store.foo writes to and reads from :foo)" do
      store = described_class.new
      store.foo = "bar"
      expect(store[:foo]).to eq "bar"
    end

    it "bracket access with a symbol reads and writes using the symbol key" do
      store = described_class.new
      store[:foo] = "bar"
      expect(store[:foo]).to eq "bar"
    end

    it "bracket access with a string reads and writes using the string key" do
      store = described_class.new
      store["foo"] = "bar"
      expect(store["foo"]).to eq "bar"
    end

    context "with cross-access" do
      it "store.foo writes a value readable via store[:foo]" do
        store = described_class.new
        store.foo = "bar"
        expect(store[:foo]).to eq "bar"
      end

      it "store[:baz] writes a value readable via store.baz" do
        store = described_class.new
        store[:baz] = "qux"
        expect(store.baz).to eq "qux"
      end

      it 'store.foo and store["foo"] do NOT access the same value' do
        store = described_class.new
        store.foo = "bar"
        expect(store["foo"]).not_to eq "bar"
      end
    end
  end

  describe "method name collisions" do
    context "with methods defined on Object (class, freeze, hash, object_id, send, display)" do
      subject { described_class.new({ class: "fancy", freeze: "cold" }) }

      it "are not intercepted by method_missing" do
        expect(subject.class).to eq described_class
        expect(subject.object_id).to be_a Integer
      end

      it "values stored under those keys are accessible via bracket" do
        expect(subject[:class]).to eq "fancy"
        expect(subject[:freeze]).to eq "cold"
      end
    end

    context "with methods defined on Flexor (to_h, to_s, nil?, ==)" do
      subject { described_class.new({ to_h: "override", to_s: "nope", nil?: "not nil" }) }

      it "are not intercepted by method_missing" do
        expect(subject.to_h).to be_a Hash
        expect(subject.nil?).to be(false).or be(true)
      end

      it "to_h and to_s values are accessible via bracket" do
        expect(subject[:to_h]).to eq "override"
        expect(subject[:to_s]).to eq "nope"
      end

      it "nil? value is accessible via bracket" do
        expect(subject[:nil?]).to eq "not nil"
      end
    end
  end
end
