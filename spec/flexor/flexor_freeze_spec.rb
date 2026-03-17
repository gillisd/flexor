RSpec.describe Flexor do
  describe "freeze" do
    context "when freezing a Flexor" do
      it "prevents further writes" do
        store = described_class.new({ a: 1 })
        store.freeze
        expect { store.b = 2 }.to raise_error(FrozenError)
      end

      it "reads still work" do
        store = described_class.new({ a: 1 })
        store.freeze
        expect(store.a).to eq 1
      end

      it "autovivification raises on frozen store" do
        store = described_class.new
        store.freeze
        expect { store[:missing] }.to raise_error(FrozenError)
      end

      it "merge! on a frozen Flexor raises FrozenError" do
        store = described_class.new({ a: 1 })
        store.freeze
        expect { store.merge!({ b: 2 }) }.to raise_error(FrozenError)
      end

      it "delete on a frozen Flexor raises FrozenError" do
        store = described_class.new({ a: 1 })
        store.freeze
        expect { store.delete(:a) }.to raise_error(FrozenError)
      end

      it "clear on a frozen Flexor raises FrozenError" do
        store = described_class.new({ a: 1 })
        store.freeze
        expect { store.clear }.to raise_error(FrozenError)
      end

      it "set_raw on a frozen Flexor raises FrozenError" do
        store = described_class.new({ a: 1 })
        store.freeze
        expect { store.set_raw(:b, 2) }.to raise_error(FrozenError)
      end

      it "dup of a frozen Flexor returns an unfrozen copy" do
        store = described_class.new({ a: 1 })
        store.freeze
        copy = store.dup
        expect(copy).not_to be_frozen
        expect(copy.to_h).to eq({ a: 1 })
      end

      it "clone of a frozen Flexor returns a frozen copy" do
        store = described_class.new({ a: 1 })
        store.freeze
        copy = store.clone
        expect(copy).to be_frozen
      end
    end
  end
end
