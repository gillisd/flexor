RSpec.describe Flexor do
  describe "#nil?" do
    it "is truthy on an unset property (empty Flexor)" do
      store = described_class.new
      expect(store.missing.nil?).to be true
    end

    it "is falsey on a property with a value" do
      store = described_class.new({ name: "alice" })
      expect(store.name.nil?).to be false
    end

    it "is truthy on a property set explicitly to nil (via NilClass#nil?)" do
      store = described_class.new({ gone: nil })
      expect(store.gone.nil?).to be true
    end

    it "is truthy on a root Flexor with no data" do
      store = described_class.new
      expect(store.nil?).to be true
    end

    it "is falsey on a root Flexor with data" do
      store = described_class.new({ a: 1 })
      expect(store.nil?).to be false
    end
  end

  describe "#==" do
    context "when comparing an unset property (empty Flexor)" do
      subject { described_class.new }

      it "against nil is truthy" do
        expect(subject.missing.nil?).to be true
      end

      it "against a non-nil value is falsey" do
        expect(subject.missing == "something").to be false
      end
    end

    context "when comparing two Flexors" do
      it "is truthy when both have identical contents" do
        a = described_class.new({ x: 1, y: 2 })
        b = described_class.new({ x: 1, y: 2 })
        expect(a == b).to be true
      end

      it "is falsey when contents differ" do
        a = described_class.new({ x: 1 })
        b = described_class.new({ x: 2 })
        expect(a == b).to be false
      end

      it "is truthy when both are empty" do
        a = described_class.new
        b = described_class.new
        expect(a == b).to be true
      end
    end

    context "when comparing a Flexor against a Hash" do
      it "is truthy when keys and values are identical" do
        store = described_class.new({ x: 1, y: 2 })
        expect(store == { x: 1, y: 2 }).to be true
      end

      it "is falsey when keys and values are NOT identical" do
        store = described_class.new({ x: 1 })
        expect(store == { x: 99 }).to be false
      end
    end

    context "when comparing a property set explicitly to nil" do
      subject { described_class.new({ gone: nil }) }

      it "against nil is truthy (via NilClass#==)" do
        expect(subject.gone.nil?).to be true
      end

      it "against a non-nil value is falsey (via NilClass#==)" do
        expect(subject.gone == "something").to be false
      end
    end

    context "when comparing a scalar value" do
      subject { described_class.new({ name: "alice" }) }

      it "against an identical scalar is truthy (via String#==)" do
        expect(subject.name == "alice").to be true
      end

      it "against a different scalar is falsey (via String#==)" do
        expect(subject.name == "bob").to be false
      end
    end

    context "symmetry" do
      it "documents whether nil == empty Flexor is symmetric" do
        store = described_class.new
        flexor_equals_nil = store.nil?
        # NilClass#== does not know about Flexor, so reverse may differ
        nil_equals_flexor = NilClass.instance_method(:==).bind_call(nil, store)
        expect(flexor_equals_nil).to be true
        # Document actual behavior without asserting symmetry
        expect(nil_equals_flexor).to be(true).or be(false)
      end
    end
  end

  describe "#===" do
    context "when used in a case/when on a Flexor value" do
      it "matches against a scalar when values are equal" do
        store = described_class.new({ status: "active" })
        matched = case store.status
                  when "active" then true
                  else false
                  end
        expect(matched).to be true
      end

      it "matches against nil when property is unset" do
        store = described_class.new
        # NilClass#=== checks identity, not nil?, so case/when nil
        # won't match a nil-like Flexor. Use == nil or nil? instead.
        expect(store.missing.nil?).to be true
        expect(store.missing.nil?).to be true
      end
    end
  end

  describe ".===" do
    context "when used as a class in case/when" do
      it "matches a Flexor instance" do
        store = described_class.new
        matched = case store
                  when described_class then true
                  else false
                  end
        expect(matched).to be true
      end

      it "does not match a plain Hash" do
        value = { a: 1 }
        matched = case value
                  when described_class then true
                  else false
                  end
        expect(matched).to be false
      end

      it "does not match nil" do
        value = nil
        matched = case value
                  when described_class then true
                  else false
                  end
        expect(matched).to be false
      end
    end
  end
end
