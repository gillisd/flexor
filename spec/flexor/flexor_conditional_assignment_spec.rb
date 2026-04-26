RSpec.describe Flexor do
  let(:f) { described_class.new }

  describe "f[:foo] ||= :bar" do
    context "when the key is unset" do
      it "assigns the value" do
        f[:foo] ||= :bar
        expect(f.foo).to eq(:bar)
        expect(f[:foo]).to eq(:bar)
      end
    end

    context "when the key has been method-touched but not assigned" do
      before { _ = f.foo }

      it "assigns the value" do
        f[:foo] ||= :bar
        expect(f.foo).to eq(:bar)
        expect(f[:foo]).to eq(:bar)
      end
    end
  end

  describe "f[:foo] || (f[:foo] = :bar)" do
    context "when the key is unset" do
      it "assigns the value" do
        f[:foo] || f[:foo] = :bar
        expect(f.foo).to eq(:bar)
        expect(f[:foo]).to eq(:bar)
      end
    end

    context "when the key has been method-touched but not assigned" do
      before { _ = f.foo }

      it "assigns the value" do
        f[:foo] || f[:foo] = :bar
        expect(f.foo).to eq(:bar)
        expect(f[:foo]).to eq(:bar)
      end
    end
  end

  describe "f[:foo].nil? && (f[:foo] = :bar)" do
    context "when the key is unset" do
      it "assigns the value" do
        f[:foo].nil? && f[:foo] = :bar
        expect(f.foo).to eq(:bar)
        expect(f[:foo]).to eq(:bar)
      end
    end

    context "when the key has been method-touched but not assigned" do
      before { _ = f.foo }

      it "assigns the value" do
        f[:foo].nil? && f[:foo] = :bar
        expect(f.foo).to eq(:bar)
        expect(f[:foo]).to eq(:bar)
      end
    end
  end
end
