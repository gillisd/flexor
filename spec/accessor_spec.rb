require "flexor"
require "rspec"

RSpec.describe "accessor parity between Hash and Flexor" do
  describe Hash do
    context "when hash has no field set" do
      it "has value of nil" do
        h = {}
        expect(h[:foo]).to be_nil
      end

      describe "setting via ||=" do
        it "sets the attribute" do
          h = {}
          h[:foo] ||= :bar
          expect(h[:foo]).to eq(:bar)
        end
      end

      describe "setting via implicit nil OR" do
        it "correctly sets the attribute" do
          h = {}
          h[:foo] || h[:foo] = :bar
          expect(h[:foo]).to eq(:bar)
        end
      end

      describe "setting via nil? OR" do
        it "correctly sets the attribute" do
          h = {}
          h[:foo].nil? && h[:foo] = :bar
          expect(h[:foo]).to eq(:bar)
        end
      end
    end
  end

  describe Flexor do
    context "when flexor has no field set" do
      it "has value of nil" do
        f = described_class.new
        expect(f.foo).to be_nil
        expect(f[:foo]).to be_nil
      end

      describe "setting via ||=" do
        it "sets the attribute" do
          f = described_class.new
          f[:foo] ||= :bar
          expect(f.foo).to eq(:bar)
          expect(f[:foo]).to eq(:bar)
        end
      end

      describe "setting via implicit nil OR" do
        it "correctly sets the attribute" do
          f = described_class.new
          f[:foo] || f[:foo] = :bar
          expect(f.foo).to eq(:bar)
          expect(f[:foo]).to eq(:bar)
        end
      end

      describe "setting via nil? OR" do
        it "correctly sets the attribute" do
          f = described_class.new
          f[:foo].nil? && f[:foo] = :bar
          expect(f.foo).to eq(:bar)
          expect(f[:foo]).to eq(:bar)
        end
      end
    end
  end
end
