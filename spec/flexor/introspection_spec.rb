RSpec.describe Flexor do
  describe "method_missing edge cases" do
    subject { described_class.new({foo: "bar"}) }

    it "calling a method with arguments (store.foo(1)) raises NoMethodError" do
      expect { subject.foo(1) }.to raise_error(NoMethodError)
    end

    it "calling a method with a block raises NoMethodError" do
      expect { subject.foo { "block" } }.to raise_error(NoMethodError)
    end

    it "setter with too many arguments (store.foo = 1, 2) raises NoMethodError" do
      expect { subject.send(:foo=, 1, 2) }.to raise_error(NoMethodError)
    end
  end

  describe "#respond_to?" do
    subject { described_class.new }

    it "is truthy for any arbitrary method name" do
      expect(subject.respond_to?(:anything)).to be true
      expect(subject.respond_to?(:made_up_method)).to be true
    end

    it "is truthy for method names that also exist on Object" do
      expect(subject.respond_to?(:class)).to be true
      expect(subject.respond_to?(:object_id)).to be true
    end

    it "is truthy with include_private: true" do
      expect(subject.respond_to?(:anything, true)).to be true
    end
  end

  describe "#respond_to_missing?" do
    subject { described_class.new }

    it "returns true for any method name" do
      expect(subject.respond_to_missing?(:anything)).to be true
    end
  end
end
