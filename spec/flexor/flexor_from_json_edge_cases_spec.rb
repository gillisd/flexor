RSpec.describe Flexor do
  describe ".from_json" do
    context "with a JSON array root" do
      it "raises ArgumentError for an Array" do
        expect { described_class.from_json("[1, 2, 3]") }.to raise_error(ArgumentError, /Array/)
      end
    end

    context "with a JSON null root" do
      it "raises ArgumentError for nil" do
        expect { described_class.from_json("null") }.to raise_error(ArgumentError, /NilClass/)
      end
    end

    context "with a JSON scalar root" do
      it "raises ArgumentError for a String" do
        expect { described_class.from_json('"just a string"') }.to raise_error(ArgumentError, /String/)
      end
    end
  end
end
