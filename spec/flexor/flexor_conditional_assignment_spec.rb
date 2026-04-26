RSpec.describe Flexor do
  shared_examples "an operator that assigns to a bracket-accessed key" do
    context "when the key is unset" do
      let(:flexor) { described_class.new }

      it "assigns the value" do
        operation.call(flexor)
        expect(flexor.foo).to eq(:bar)
        expect(flexor[:foo]).to eq(:bar)
      end
    end

    context "when the key has been method-touched but not assigned" do
      let(:flexor) do
        f = described_class.new
        _ = f.foo
        f
      end

      it "assigns the value" do
        operation.call(flexor)
        expect(flexor.foo).to eq(:bar)
        expect(flexor[:foo]).to eq(:bar)
      end
    end
  end

  describe "f[:foo] ||= :bar" do
    it_behaves_like "an operator that assigns to a bracket-accessed key" do
      let(:operation) { ->(f) { f[:foo] ||= :bar } }
    end
  end

  describe "f[:foo] || (f[:foo] = :bar)" do
    it_behaves_like "an operator that assigns to a bracket-accessed key" do
      let(:operation) { ->(f) { f[:foo] || f[:foo] = :bar } }
    end
  end

  describe "f[:foo].nil? && (f[:foo] = :bar)" do
    it_behaves_like "an operator that assigns to a bracket-accessed key" do
      let(:operation) { ->(f) { f[:foo].nil? && f[:foo] = :bar } }
    end
  end
end
