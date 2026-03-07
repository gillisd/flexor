RSpec.describe Flexor do
  describe ".from_json" do
    context "with a JSON array root" do
      it "raises ArgumentError for an Array"
    end

    context "with a JSON null root" do
      it "raises ArgumentError for nil"
    end

    context "with a JSON scalar root" do
      it "raises ArgumentError for a String"
    end
  end
end
