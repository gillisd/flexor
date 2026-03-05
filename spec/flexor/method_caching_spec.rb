RSpec.describe Flexor do
  describe "method caching" do
    it "defines a singleton method after first read" do
      store = described_class.new({ name: "alice" })
      expect(store.singleton_methods).not_to include(:name)
      store.name
      expect(store.singleton_methods).to include(:name)
    end

    it "defines a singleton method after first write" do
      store = described_class.new
      expect(store.singleton_methods).not_to include(:name=)
      store.name = "alice"
      expect(store.singleton_methods).to include(:name=)
    end

    it "cached getter returns the correct value" do
      store = described_class.new({ name: "alice" })
      store.name
      expect(store.name).to eq "alice"
    end

    it "cached getter reflects updated values" do
      store = described_class.new({ name: "alice" })
      store.name
      store.name = "bob"
      expect(store.name).to eq "bob"
    end

    it "cached setter writes correctly" do
      store = described_class.new
      store.name = "alice"
      store.name = "bob"
      expect(store.name).to eq "bob"
    end

    it "cached getter on missing key returns nil-like Flexor" do
      store = described_class.new
      store.missing
      expect(store.missing).to be_nil
      expect(store.missing).to be_a described_class
    end

    it "cached getter still raises NoMethodError with a block" do
      store = described_class.new({ foo: "bar" })
      store.foo
      expect { store.foo { "block" } }.to raise_error(NoMethodError)
    end

    it "cached getter still raises NoMethodError with arguments" do
      store = described_class.new({ foo: "bar" })
      store.foo
      expect { store.foo(1) }.to raise_error(NoMethodError)
    end

    it "does not cache methods that already exist on Flexor" do
      store = described_class.new({ to_h: "override", nil?: "nope" })
      store.to_h
      expect(store.singleton_methods).not_to include(:to_h)
    end

    it "caching does not leak between instances" do
      a = described_class.new({ name: "alice" })
      b = described_class.new({ age: 30 })
      a.name
      expect(b.singleton_methods).not_to include(:name)
    end

    it "works correctly with nested chaining" do
      store = described_class.new({ user: { name: "alice" } })
      store.user.name
      expect(store.user.name).to eq "alice"
      store.user.name = "bob"
      expect(store.user.name).to eq "bob"
    end
  end
end
