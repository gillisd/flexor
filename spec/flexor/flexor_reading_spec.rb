RSpec.describe Flexor do
  describe "reading a level 1 property via method" do
    context "when the property exists" do
      subject { described_class.new({ foo: "bar" }) }

      it "reads the correct property" do
        expect(subject.foo).to eq "bar"
      end
    end

    context "when the property does not exist" do
      subject { described_class.new({}) }

      it "returns a value where nil? is true" do
        expect(subject.foo).to be_nil
      end

      it "returns a value that == nil" do
        expect(subject.foo.nil?).to be true
      end

      it "does not return the nil singleton" do
        expect(subject.foo).not_to equal nil
      end

      it "returns a Flexor" do
        expect(subject.foo).to be_a described_class
      end
    end
  end

  describe "reading a level 1 property via hash accessor" do
    context "when the property exists" do
      subject { described_class.new({ foo: "bar" }) }

      it "reads the correct property" do
        expect(subject[:foo]).to eq "bar"
      end
    end

    context "when the property does not exist" do
      subject { described_class.new({}) }

      it "returns the nil singleton" do
        expect(subject[:foo]).to equal nil
      end

      it "satisfies be_nil and responds true to nil?" do
        expect(subject[:foo]).to be_nil
        expect(subject[:foo].nil?).to be true
      end

      it "is not a Flexor instance" do
        expect(subject[:foo]).not_to be_a described_class
      end
    end
  end

  describe "reading a level 2 property via method" do
    context "when the level 1 property exists" do
      subject { described_class.new({ user: { name: "alice" } }) }

      context "when the level 2 property exists" do
        it "reads the correct property" do
          expect(subject.user.name).to eq "alice"
        end
      end

      context "when the level 2 property does not exist" do
        it "returns a value where nil? is true" do
          expect(subject.user.missing).to be_nil
        end
      end
    end

    context "when the level 1 property does not exist" do
      subject { described_class.new({}) }

      it "returns a value where nil? is true" do
        expect(subject.missing.also_missing).to be_nil
      end

      it "the returned value is itself a Flexor that supports further chaining" do
        result = subject.missing
        expect(result).to be_a described_class
        expect(result.deeper.still).to be_nil
      end
    end
  end

  describe "reading a level 2 property via hash accessor" do
    context "when the level 1 property exists" do
      subject { described_class.new({ user: { name: "alice" } }) }

      context "when the level 2 property exists" do
        it "reads the correct property" do
          expect(subject[:user][:name]).to eq "alice"
        end
      end

      context "when the level 2 property does not exist" do
        it "returns a value where nil? is true" do
          expect(subject[:user][:missing]).to be_nil
        end
      end
    end

    context "when the level 1 property does not exist" do
      subject { described_class.new({}) }

      it "returns nil at level 1" do
        expect(subject[:missing]).to be_nil
      end

      it "raises NoMethodError when chaining brackets through a missing key" do
        expect { subject[:missing][:also_missing] }.to raise_error(NoMethodError)
      end
    end
  end

  describe "reading at arbitrary depth (3+ levels)" do
    context "when all levels are set" do
      subject { described_class.new({ a: { b: { c: { d: "deep" } } } }) }

      it "reads the correct property" do
        expect(subject.a.b.c.d).to eq "deep"
      end
    end

    context "when no levels are set" do
      subject { described_class.new({}) }

      it "returns nil at level 1" do
        expect(subject.a).to be_nil
      end

      it "returns nil at level 2" do
        expect(subject.a.b).to be_nil
      end

      it "returns nil at level 3" do
        expect(subject.a.b.c).to be_nil
      end

      it "supports chaining to any depth without error" do
        expect { subject.a.b.c.d.e.f.g }.not_to raise_error
      end
    end
  end

  describe "method vs bracket access equivalence" do
    subject { described_class.new({ foo: "bar" }) }

    context "when reading the same key via method and bracket" do
      it "for a set property" do
        expect(subject.foo).to eq subject[:foo]
      end

      it "for an unset property" do
        method_result = subject.missing
        bracket_result = subject[:missing]
        expect(method_result).to be_nil
        expect(bracket_result).to be_nil
      end
    end

    it "writing via method and reading via bracket returns the written value" do
      subject.baz = "qux"
      expect(subject[:baz]).to eq "qux"
    end

    it "writing via bracket and reading via method returns the written value" do
      subject[:baz] = "qux"
      expect(subject.baz).to eq "qux"
    end
  end
end
