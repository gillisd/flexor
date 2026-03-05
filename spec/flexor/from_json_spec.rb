RSpec.describe Flexor do
  describe ".from_json" do
    context "with valid flat JSON" do
      let(:json) { '{"name": "alice", "age": 30}' }

      subject { described_class.from_json(json) }

      it "creates a Flexor with symbolized keys" do
        expect(subject[:name]).to eq "alice"
        expect(subject[:age]).to eq 30
      end

      it "allows method access on parsed values" do
        expect(subject.name).to eq "alice"
      end
    end

    context "with nested JSON" do
      let(:json) { '{"user": {"name": "alice", "address": {"city": "NYC"}}}' }

      subject { described_class.from_json(json) }

      it "recursively converts nested objects" do
        expect(subject[:user]).to be_a described_class
      end

      it "allows method chaining on nested values" do
        expect(subject.user.address.city).to eq "NYC"
      end
    end

    context "with JSON containing arrays" do
      let(:json) { '{"tags": ["a", "b"], "items": [{"id": 1}]}' }

      subject { described_class.from_json(json) }

      it "preserves arrays" do
        expect(subject.tags).to eq ["a", "b"]
      end

      it "converts objects inside arrays into Flexors" do
        expect(subject.items.first).to be_a described_class
        expect(subject.items.first.id).to eq 1
      end
    end

    context "with invalid JSON" do
      it "raises a parse error" do
        expect { described_class.from_json("not json") }.to raise_error(JSON::ParserError)
      end
    end
  end
end
