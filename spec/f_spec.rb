require "spec_helper"
require "f"

RSpec.describe F do
  it "is the Flexor class" do
    expect(described_class).to equal Flexor
  end

  it "creates a Flexor via F[]" do
    expect(described_class[name: "alice"]).to be_a Flexor
  end

  it "allows method access on parsed values" do
    expect(described_class[name: "alice"].name).to eq "alice"
  end
end
