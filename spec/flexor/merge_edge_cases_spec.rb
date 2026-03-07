RSpec.describe Flexor do
  describe "#merge!" do
    context "with nil values" do
      it "nil overwrites an existing scalar"

      it "nil overwrites an existing nested Flexor"

      it "nil inside a nested hash is preserved during deep merge"
    end
  end

  describe "#merge" do
    context "with nil values" do
      it "nil overwrites an existing scalar in the new Flexor"

      it "nil inside a nested hash is preserved during deep merge"
    end
  end
end
