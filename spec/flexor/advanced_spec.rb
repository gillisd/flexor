RSpec.describe Flexor do
  describe "array handling end-to-end" do
    context "via constructor" do
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

    context "via direct assignment" do
      it "assigning an array of hashes does not auto-convert" do
        store = described_class.new
        store.items = [{ id: 1 }, { id: 2 }]
        expect(store.items.first).to be_a Hash
      end
    end

    context "reading from arrays stored in Flexor" do
      it "array elements are accessible via standard array methods" do
        store = described_class.new({ tags: ["a", "b", "c"] })
        expect(store.tags.first).to eq "a"
        expect(store.tags.last).to eq "c"
        expect(store.tags.length).to eq 3
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
      threads = Array.new(10) do
        Thread.new {
          100.times {
            store.a
            store.b
            store.c
          }
        }
      end
      expect { threads.each(&:join) }.not_to raise_error
    end

    it "concurrent writes to different keys documents expected behavior" do
      store = described_class.new
      threads = Array.new(10) do |i|
        Thread.new { store[:"key_#{i}"] = i }
      end
      expect { threads.each(&:join) }.not_to raise_error
    end

    it "concurrent autovivification documents expected behavior" do
      store = described_class.new
      threads = Array.new(10) do |i|
        Thread.new { _ = store[:"auto_#{i}"] }
      end
      expect { threads.each(&:join) }.not_to raise_error
    end
  end

  describe "dup and clone" do
    context "duping a Flexor" do
      it "returns a new Flexor with the same contents" do
        original = described_class.new({ a: 1, b: 2 })
        copy = original.dup
        expect(copy).to be_a described_class
        expect(copy.to_h).to eq original.to_h
        expect(copy).not_to equal original
      end

      it "modifications to the dup do not affect the original" do
        original = described_class.new({ a: 1 })
        copy = original.dup
        copy.b = 2
        expect(original.to_h.keys).not_to include(:b)
      end
    end

    context "cloning a Flexor" do
      it "returns a new Flexor with the same contents" do
        original = described_class.new({ a: 1, b: 2 })
        copy = original.clone
        expect(copy).to be_a described_class
        expect(copy.to_h).to eq original.to_h
        expect(copy).not_to equal original
      end

      it "modifications to the clone do not affect the original" do
        original = described_class.new({ a: 1 })
        copy = original.clone
        copy.b = 2
        expect(original.to_h.keys).not_to include(:b)
      end
    end

    context "deep nesting" do
      it "dup is shallow (nested Flexors are shared)" do
        original = described_class.new({ nested: { a: 1 } })
        copy = original.dup
        copy.nested.a = 99
        expect(original.nested.a).to eq 99
      end
    end
  end

  describe "freeze" do
    context "freezing a Flexor" do
      it "prevents further writes" do
        store = described_class.new({ a: 1 })
        store.freeze
        expect { store.b = 2 }.to raise_error(FrozenError)
      end

      it "reads still work" do
        store = described_class.new({ a: 1 })
        store.freeze
        expect(store.a).to eq 1
      end

      it "autovivification raises on frozen store" do
        store = described_class.new
        store.freeze
        expect { store[:missing] }.to raise_error(FrozenError)
      end
    end
  end

  describe "enumeration" do
    context "each / map / select" do
      subject { described_class.new({ a: 1, b: 2, c: 3 }) }

      it "delegates to the underlying store" do
        keys = []
        subject.each_key { |k| keys << k }
        expect(keys).to contain_exactly(:a, :b, :c)
      end

      it "map works on the store" do
        result = subject.map { |k, _v| k }
        expect(result).to contain_exactly(:a, :b, :c)
      end

      it "select works on the store" do
        result = subject.select { |_k, v| v.is_a?(Integer) && v > 1 }
        expect(result.map(&:first)).to contain_exactly(:b, :c)
      end
    end
  end
end
