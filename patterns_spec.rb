require "rspec"

FLOAT = /^(?:(?<!0)(?:[-+] ?)?[0-9])+(?:\.(?:[0-9](?!\.))+)?$/
RSpec.describe "Patterns" do
  describe FLOAT do
    it "does not allow leading zeroes" do
      skip "not done yet"
    end
  end
end
