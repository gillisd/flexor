RSpec.describe Flexor do
  describe "writing a level 1 property via method" do
    subject { described_class.new }

    it "writes and reads the written property" do
      subject.foo = "bar"
      expect(subject.foo).to eq "bar"
    end
  end

  describe "writing a level 1 property via hash accessor" do
    subject { described_class.new }

    it "writes and reads the written property" do
      subject[:foo] = "bar"
      expect(subject[:foo]).to eq "bar"
    end
  end

  describe "writing a level 2 property via method" do
    context "when the level 1 property has been set" do
      subject { described_class.new({ rank: { first: 1 } }) }

      it "writes and reads the written property" do
        subject.rank.second = 2
        expect(subject.rank.second).to eq 2
      end
    end

    context "when the level 1 property has not been set" do
      subject { described_class.new }

      it "vivifies the level 1 property" do
        subject.rank.first = 1
        expect(subject.rank).to be_a described_class
        expect(subject.rank).not_to be_nil
      end

      it "writes and reads the written property" do
        subject.rank.first = 1
        expect(subject.rank.first).to eq 1
      end
    end
  end

  describe "writing a level 2 property via hash accessor" do
    context "when the level 1 property has been set" do
      subject { described_class.new({ rank: { first: 1 } }) }

      it "writes and reads the written property" do
        subject[:rank][:second] = 2
        expect(subject[:rank][:second]).to eq 2
      end
    end

    context "when the level 1 property has not been set" do
      subject { described_class.new }

      it "raises NoMethodError when writing through an unset bracket" do
        expect { subject[:rank][:first] = 1 }.to raise_error(NoMethodError)
      end

      it "supports method-style vivification followed by bracket write" do
        subject.rank[:first] = 1
        expect(subject[:rank][:first]).to eq 1
      end
    end
  end

  describe "writing at arbitrary depth (3+ levels)" do
    subject { described_class.new }

    context "when no intermediate levels are set" do
      it "vivifies every intermediate level" do
        subject.a.b.c = "deep"
        expect(subject.a).to be_a described_class
        expect(subject.a.b).to be_a described_class
      end

      it "writes and reads the written property" do
        subject.a.b.c = "deep"
        expect(subject.a.b.c).to eq "deep"
      end
    end
  end

  describe "assigning a plain hash via setter" do
    subject { described_class.new }

    context "when assigning a hash" do
      before { subject.config = { db: { host: "localhost" } } }

      it "bracket access returns a Flexor, not a Hash" do
        expect(subject[:config]).to be_a described_class
      end

      it "method chaining works on the assigned value" do
        expect(subject.config.db.host).to eq "localhost"
      end
    end
  end

  describe "assigning an array via setter" do
    subject { described_class.new }

    context "with an array of scalars" do
      it "stores and retrieves the array" do
        subject.tags = ["a", "b", "c"]
        expect(subject.tags).to eq ["a", "b", "c"]
      end
    end

    context "with an array of hashes" do
      it "auto-converts inner hashes to Flexors" do
        subject.items = [{ id: 1 }, { id: 2 }]
        expect(subject.items.first).to be_a described_class
        expect(subject.items.first.id).to eq 1
      end
    end
  end

  describe "overwriting" do
    subject { described_class.new({ user: { name: "alice", age: 30 } }) }

    it "replacing a nested subtree with a scalar stores the scalar" do
      subject.user = "gone"
      expect(subject.user).to eq "gone"
    end

    it "replacing a nested subtree with a scalar removes the old subtree" do
      subject.user = "gone"
      expect { subject.user.name }.to raise_error(NoMethodError)
    end

    it "replacing a scalar with a nested write vivifies the new path" do
      subject.user = "flat"
      subject.user = { first: "carol" }
      expect(subject[:user]).to be_a described_class
      expect(subject.user.first).to eq "carol"
    end

    it "replacing a scalar with nil makes the property read as nil" do
      subject.user.name = "bob"
      subject.user.name = nil
      expect(subject.user.name).to be_nil
    end
  end

  describe "#set_raw" do
    subject { described_class.new }

    it "stores a hash without vivification" do
      subject.set_raw(:config, { db: { host: "localhost" } })
      expect(subject[:config]).to be_a Hash
      expect(subject[:config]).not_to be_a described_class
    end

    it "stores an array of hashes without vivification" do
      subject.set_raw(:items, [{ id: 1 }, { id: 2 }])
      expect(subject.items.first).to be_a Hash
    end

    it "stores scalars normally" do
      subject.set_raw(:name, "alice")
      expect(subject.name).to eq "alice"
    end
  end
end
