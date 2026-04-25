require "flexor"
require "rspec"

RSpec.describe Hash do
  context "when hash has no field set" do
    it 'has value of nil' do
      h = Hash.new
      expect(h[:foo]).to eq nil
    end

    describe "setting via ||=" do
      it "sets the attribute" do
        h = Hash.new
        h[:foo] ||= :bar
        expect(h[:foo]).to eq(:bar)
      end
    end

    describe "setting via implicit nil OR" do
      it "correctly sets the attribute" do
        h = Hash.new
        h[:foo] || h[:foo] = :bar
        expect(h[:foo]).to eq(:bar)
      end
    end

    describe "setting via nil? OR" do
      it "correctly sets the attribute" do
        h = Hash.new
        h[:foo].nil? && h[:foo] = :bar
        expect(h[:foo]).to eq(:bar)
      end
    end
  end
end

RSpec.describe Flexor do
  context "when flexor has no field set" do
    it 'has value of nil' do
      f = Flexor.new
      expect(f.foo).to eq nil
      expect(f[:foo]).to eq nil
    end

    describe "setting via ||=" do
      it "sets the attribute" do
        f = Flexor.new
        f[:foo] ||= :bar
        expect(f.foo).to eq(:bar)
        expect(f[:foo]).to eq(:bar)
      end
    end

    describe "setting via implicit nil OR" do
      it "correctly sets the attribute" do
        f = Flexor.new
        f[:foo] || f[:foo] = :bar
        expect(f.foo).to eq(:bar)
        expect(f[:foo]).to eq(:bar)
      end
    end

    describe "setting via nil? OR" do
      it "correctly sets the attribute" do
        f = Flexor.new
        f[:foo].nil? && f[:foo] = :bar
        expect(f.foo).to eq(:bar)
        expect(f[:foo]).to eq(:bar)
      end
    end
  end
end
