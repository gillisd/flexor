RSpec.describe Flexor do
  describe "method_missing edge cases" do
    subject { described_class.new({ foo: "bar" }) }

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

  describe "error message clarity" do
    context "with constructor ArgumentError" do
      it "includes the actual class in the error message" do
        expect { described_class.new("string") }.to raise_error(
          ArgumentError, /String/
        )
      end
    end

    context "with NoMethodError from cached getter" do
      it "includes the method name after caching" do
        store = described_class.new({ foo: "bar" })
        store.foo # cache the getter
        expect { store.foo(1) }.to raise_error(NoMethodError, /foo/)
      end
    end

    context "with NoMethodError from method_missing" do
      it "includes the method name before caching" do
        store = described_class.new({ foo: "bar" })
        expect { store.foo(1) }.to raise_error(NoMethodError, /foo/)
      end
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
      expect(subject.send(:respond_to_missing?, :anything)).to be true
    end
  end
end
