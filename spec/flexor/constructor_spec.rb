RSpec.describe Flexor do
  describe ".new" do
    context "with no arguments" do
      subject { described_class.new }

      it "creates an empty store" do
        expect(subject.to_h).to eq({})
      end

      it "is a root Flexor" do
        expect(subject.instance_variable_get(:@root)).to be true
      end
    end

    context "with an empty hash" do
      subject { described_class.new({}) }

      it "creates an empty store" do
        expect(subject.to_h).to eq({})
      end
    end

    context "with a flat hash" do
      subject { described_class.new({ name: "alice", age: 30 }) }

      it "stores all key-value pairs" do
        expect(subject.to_h).to eq({ name: "alice", age: 30 })
      end

      it "allows method access on each key" do
        expect(subject.name).to eq "alice"
        expect(subject.age).to eq 30
      end

      it "allows bracket access on each key" do
        expect(subject[:name]).to eq "alice"
        expect(subject[:age]).to eq 30
      end
    end

    context "with a nested hash" do
      subject { described_class.new({ user: { name: "alice" } }) }

      it "recursively converts nested hashes into Flexors" do
        expect(subject[:user]).to be_a described_class
      end

      it "allows method access at every level" do
        expect(subject.user.name).to eq "alice"
      end

      it "allows bracket access at every level" do
        expect(subject[:user][:name]).to eq "alice"
      end
    end

    context "with a deeply nested hash (3+ levels)" do
      subject { described_class.new({ a: { b: { c: "deep" } } }) }

      it "allows method access at every level" do
        expect(subject.a.b.c).to eq "deep"
      end

      it "allows bracket access at every level" do
        expect(subject[:a][:b][:c]).to eq "deep"
      end
    end

    context "with a hash containing arrays" do
      subject { described_class.new({ tags: ["a", "b"], items: [{ id: 1 }, { id: 2 }] }) }

      it "preserves arrays of scalars" do
        expect(subject.tags).to eq ["a", "b"]
      end

      it "converts hashes inside arrays into Flexors" do
        expect(subject.items.first).to be_a described_class
        expect(subject.items.first.id).to eq 1
      end

      it "preserves non-hash elements in mixed arrays" do
        store = described_class.new({ mix: [1, { a: 2 }, "three"] })
        expect(store.mix[0]).to eq 1
        expect(store.mix[1]).to be_a described_class
        expect(store.mix[2]).to eq "three"
      end
    end

    context "with a hash containing nil values" do
      subject { described_class.new({ gone: nil }) }

      it "stores the nil value directly" do
        expect(subject[:gone]).to be_nil
        expect(subject[:gone]).to equal nil
      end
    end

    context "with a non-hash argument" do
      it "raises ArgumentError" do
        expect { described_class.new("string") }.to raise_error(ArgumentError)
        expect { described_class.new(42) }.to raise_error(ArgumentError)
        expect { described_class.new([]) }.to raise_error(ArgumentError)
      end
    end

    context "when comparing root vs non-root (via .new)" do
      it "defaults to root: true" do
        store = described_class.new
        expect(store.instance_variable_get(:@root)).to be true
      end

      it "can be set to root: false" do
        store = described_class.new({}, root: false)
        expect(store.instance_variable_get(:@root)).to be false
      end
    end
  end

  describe ".[]" do
    context "with a Hash" do
      it "creates a Flexor with the given data" do
        store = described_class[name: "alice"]
        expect(store).to be_a described_class
        expect(store.name).to eq "alice"
      end
    end

    context "with a JSON string" do
      it "parses JSON and creates a Flexor" do
        store = described_class['{"name":"alice"}']
        expect(store).to be_a described_class
        expect(store.name).to eq "alice"
      end
    end

    context "with no arguments" do
      it "creates an empty Flexor" do
        store = described_class[]
        expect(store).to be_a described_class
        expect(store).to be_nil
      end
    end

    context "with a non-Hash, non-String argument" do
      it "raises ArgumentError" do
        expect { described_class[42] }.to raise_error(ArgumentError)
      end
    end
  end
end
