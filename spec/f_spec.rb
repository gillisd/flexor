require "f"

RSpec.describe F do
  it "is the Flexor class" do
    expect(described_class).to equal Flexor
  end

  it "creates a Flexor via F[]" do
    store = described_class[name: "alice"]
    expect(store).to be_a Flexor
    expect(store.name).to eq "alice"
  end
end
