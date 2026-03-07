RSpec.describe Flexor do
  describe "#has_key?" do
    it "works identically to key? for existing keys"

    it "works identically to key? for missing keys"

    it "does not autovivify the queried key"
  end

  describe "non-standard key types" do
    context "with numeric keys" do
      it "stores and retrieves values with integer keys"
    end

    context "with boolean keys" do
      it "stores and retrieves values with boolean keys"
    end

    context "with empty string keys" do
      it "stores and retrieves values with empty string keys"
    end
  end

  describe "error message clarity" do
    context "with constructor ArgumentError" do
      it "includes the actual class in the error message"
    end

    context "with NoMethodError from cached getter" do
      it "includes the method name after caching"
    end

    context "with NoMethodError from method_missing" do
      it "includes the method name before caching"
    end
  end

  describe "serialization beyond JSON" do
    context "with Marshal" do
      it "round-trips via Marshal.dump and Marshal.load"

      it "preserves autovivification after Marshal round-trip"
    end
  end
end
