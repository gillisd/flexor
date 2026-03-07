RSpec.describe Flexor do
  describe "freeze" do
    context "when freezing a Flexor" do
      it "merge! on a frozen Flexor raises FrozenError"

      it "delete on a frozen Flexor raises FrozenError"

      it "clear on a frozen Flexor raises FrozenError"

      it "set_raw on a frozen Flexor raises FrozenError"

      it "dup of a frozen Flexor returns an unfrozen copy"

      it "clone of a frozen Flexor returns a frozen copy"
    end
  end
end
