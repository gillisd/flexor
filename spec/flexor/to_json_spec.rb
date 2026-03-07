require "json"

RSpec.describe Flexor do
  describe "#to_json" do
    it "serializes scalar values" do
      store = described_class.new({ name: "alice", age: 30 })
      parsed = JSON.parse(store.to_json, symbolize_names: true)
      expect(parsed).to eq({ name: "alice", age: 30 })
    end

    it "serializes nested Flexors" do
      store = described_class.new({ user: { name: "alice" } })
      parsed = JSON.parse(store.to_json, symbolize_names: true)
      expect(parsed).to eq({ user: { name: "alice" } })
    end

    it "serializes arrays" do
      store = described_class.new({ tags: ["a", "b"], items: [{ id: 1 }] })
      parsed = JSON.parse(store.to_json, symbolize_names: true)
      expect(parsed).to eq({ tags: ["a", "b"], items: [{ id: 1 }] })
    end

    it "round-trips with from_json" do
      json = '{"user":{"name":"alice","age":30}}'
      store = described_class.from_json(json)
      parsed = JSON.parse(store.to_json, symbolize_names: true)
      expect(parsed).to eq({ user: { name: "alice", age: 30 } })
    end

    it "serializes an empty Flexor as an empty object" do
      store = described_class.new
      expect(store.to_json).to eq "{}"
    end

    it "raises when a value is not JSON-serializable"
  end
end
