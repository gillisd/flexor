RSpec.describe Flexor do
  def run_threads(count = 10, &block)
    Array.new(count) { |i| Thread.new(i, &block) }.each(&:join)
  end

  describe "array handling end-to-end" do
    context "when constructed with arrays" do
      it "hashes inside arrays are converted to Flexors" do
        store = described_class.new({ items: [{ id: 1 }] })
        expect(store.items.first).to be_a described_class
      end

      it "scalars inside arrays are preserved" do
        store = described_class.new({ tags: [1, "two", true] })
        expect(store.tags).to eq [1, "two", true]
      end

      it "nested arrays of hashes are converted recursively" do
        store = described_class.new({ matrix: [[{ a: 1 }], [{ b: 2 }]] })
        expect(store.matrix[0][0]).to be_a described_class
        expect(store.matrix[0][0].a).to eq 1
      end
    end

    context "when assigning directly" do
      it "assigning an array of hashes auto-converts inner hashes" do
        store = described_class.new
        store.items = [{ id: 1 }, { id: 2 }]
        expect(store.items.first).to be_a described_class
        expect(store.items.first.id).to eq 1
      end
    end

    context "when reading from arrays stored in Flexor" do
      subject { described_class.new({ tags: ["a", "b", "c"] }) }

      it "first element is accessible" do
        expect(subject.tags.first).to eq "a"
      end

      it "last element is accessible" do
        expect(subject.tags.last).to eq "c"
      end

      it "length is accessible" do
        expect(subject.tags.length).to eq 3
      end
    end
  end

  describe "autovivification side effects" do
    it "reading an unset property creates the key in the store (default_proc behavior)" do
      store = described_class.new
      _ = store[:phantom]
      expect(store.instance_variable_get(:@store)).to have_key(:phantom)
    end

    it "the created key holds an empty Flexor" do
      store = described_class.new
      result = store[:phantom]
      expect(result).to be_a described_class
      expect(result).to be_nil
    end

    it "chaining reads on unset properties creates keys at every intermediate level" do
      store = described_class.new
      _ = store.a.b.c
      inner_store = store.instance_variable_get(:@store)
      expect(inner_store).to have_key(:a)
    end

    it "documents whether reads leave traces in to_h" do
      store = described_class.new({ real: "data" })
      _ = store.phantom
      expect(store.to_h).to eq({ real: "data" })
    end
  end

  describe "thread safety" do
    it "concurrent reads on the same Flexor do not raise" do
      store = described_class.new({ a: 1, b: 2, c: 3 })
      expect { run_threads { 100.times { [store.a, store.b, store.c] } } }.not_to raise_error
    end

    it "concurrent writes to different keys documents expected behavior" do
      store = described_class.new
      expect { run_threads(10) { |i| store[:"key_#{i}"] = i } }.not_to raise_error
    end

    it "concurrent autovivification documents expected behavior" do
      store = described_class.new
      expect { run_threads(10) { |i| _ = store[:"auto_#{i}"] } }.not_to raise_error
    end
  end

  describe "dup and clone" do
    context "when duping a Flexor" do
      it "returns a Flexor" do
        original = described_class.new({ a: 1, b: 2 })
        expect(original.dup).to be_a described_class
      end

      it "preserves the contents" do
        original = described_class.new({ a: 1, b: 2 })
        expect(original.dup.to_h).to eq original.to_h
      end

      it "returns a different object" do
        original = described_class.new({ a: 1, b: 2 })
        expect(original.dup).not_to equal original
      end

      it "modifications to the dup do not affect the original" do
        original = described_class.new({ a: 1 })
        copy = original.dup
        copy.b = 2
        expect(original.to_h.keys).not_to include(:b)
      end
    end

    context "when cloning a Flexor" do
      it "returns a Flexor" do
        original = described_class.new({ a: 1, b: 2 })
        expect(original.clone).to be_a described_class
      end

      it "preserves the contents" do
        original = described_class.new({ a: 1, b: 2 })
        expect(original.clone.to_h).to eq original.to_h
      end

      it "returns a different object" do
        original = described_class.new({ a: 1, b: 2 })
        expect(original.clone).not_to equal original
      end

      it "modifications to the clone do not affect the original" do
        original = described_class.new({ a: 1 })
        copy = original.clone
        copy.b = 2
        expect(original.to_h.keys).not_to include(:b)
      end
    end

    context "with deep nesting" do
      it "dup is shallow (nested Flexors are shared)" do
        original = described_class.new({ nested: { a: 1 } })
        copy = original.dup
        copy.nested.a = 99
        expect(original.nested.a).to eq 99
      end
    end
  end
end
