RSpec.describe Flexor do
  describe "reading an unset key" do
    let(:store) { described_class.new({ a: 1 }) }

    it "returns a nil-like child" do
      expect(store.phantom.nil?).to be true
    end

    it "leaves the key list unchanged" do
      expect { store.phantom }.not_to(change { store.keys })
    end

    it "leaves the size unchanged" do
      expect { store.phantom }.not_to(change { store.size })
    end

    it "reports the key as absent" do
      store.phantom
      expect(store.key?(:phantom)).to be false
    end

    it "leaves the deconstructed values unchanged" do
      expect { store.phantom }.not_to(change { store.deconstruct })
    end

    it "leaves the hash conversion unchanged" do
      expect { store.phantom }.not_to(change { store.to_h })
    end

    context "with a chain of unset keys" do
      it "leaves the key list unchanged" do
        expect { store.phantom.deep.chain }.not_to(change { store.keys })
      end

      it "returns a nil-like child at every depth" do
        phantom = store.phantom
        deep = phantom.deep
        expect([phantom, deep, deep.chain].map(&:nil?)).to all(be true)
      end
    end

    context "when the unset child is written" do
      let(:child) { store.phantom }

      it "attaches the child to its parent" do
        child.x = 1
        expect(store[:phantom]).to equal child
      end

      it "adds the key to the key list" do
        expect { child.x = 1 }.to(change { store.keys }.from([:a]).to([:a, :phantom]))
      end

      it "exposes the written value through the parent" do
        child.x = 1
        expect(store.phantom.x).to eq 1
      end
    end

    context "when the end of an unset chain is written" do
      before { store.p.q.r = 1 }

      it "attaches every intermediate child" do
        expect([store.key?(:p), store.p.key?(:q), store.p.q.key?(:r)]).to all(be true)
      end

      it "renders the full path in the hash conversion" do
        expect(store.to_h).to eq({ a: 1, p: { q: { r: 1 } } })
      end
    end

    context "when two separate reads of one unset key are each written" do
      let(:first_read) { store.k }
      let(:second_read) { store.k }

      before do
        first_read.x = 1
        second_read.y = 2
      end

      it "keeps the first write" do
        expect(store.k.x).to eq 1
      end

      it "keeps the second write" do
        expect(store.k.y).to eq 2
      end
    end

    context "when the parent is frozen" do
      before { store.freeze }

      it "returns a nil-like child" do
        expect(store.phantom.nil?).to be true
      end

      it "raises no error" do
        expect { store.phantom }.not_to raise_error
      end

      context "when the unset child is written" do
        it "raises a frozen error" do
          expect { store.phantom.x = 1 }.to raise_error(FrozenError)
        end
      end
    end
  end

  describe "#eql?" do
    let(:store) { described_class.new({ x: 1 }) }

    context "with a store holding equal contents" do
      let(:twin) { described_class.new({ x: 1 }) }

      it "treats the stores as equal" do
        expect(store).to eql twin
      end
    end

    context "with a store holding different contents" do
      let(:other) { described_class.new({ x: 2 }) }

      it "treats the stores as distinct" do
        expect(store).not_to eql other
      end
    end

    context "with nested stores holding equal contents" do
      let(:store) { described_class.new({ x: { y: 1 } }) }
      let(:twin) { described_class.new({ x: { y: 1 } }) }

      it "treats the nested stores as equal" do
        expect(store).to eql twin
      end
    end

    context "with a plain hash holding equal contents" do
      it "treats the hash as distinct" do
        expect(store).not_to eql({ x: 1 })
      end
    end
  end

  describe "#==" do
    context "with a plain hash holding equal contents" do
      it "treats the hash as equal" do
        expect(described_class.new({ x: 1 })).to eq({ x: 1 })
      end
    end
  end

  describe "#hash" do
    let(:store) { described_class.new({ x: 1 }) }

    context "with stores holding equal contents" do
      let(:twin) { described_class.new({ x: 1 }) }

      it "returns the same value" do
        expect(store.hash).to eq twin.hash
      end
    end

    context "with stores holding different contents" do
      let(:other) { described_class.new({ x: 2 }) }

      it "returns different values" do
        expect(store.hash).not_to eq other.hash
      end
    end

    context "when an unset key has been read" do
      it "keeps its value" do
        expect { store.phantom }.not_to(change { store.hash })
      end
    end

    context "when a key is written" do
      it "changes its value" do
        expect { store.y = 2 }.to(change { store.hash })
      end
    end
  end

  describe "membership in collections" do
    let(:store) { described_class.new({ x: 1 }) }
    let(:twin) { described_class.new({ x: 1 }) }

    context "with equal stores in an array" do
      it "collapses them under deduplication" do
        expect([store, twin].uniq.size).to eq 1
      end
    end

    context "with equal stores as hash keys" do
      let(:index) { { store => 1, twin => 2 } }

      it "resolves them to one entry" do
        expect(index.size).to eq 1
      end

      it "keeps the last value written" do
        expect(index.fetch(store)).to eq 2
      end
    end
  end

  describe "#respond_to?" do
    let(:store) { described_class.new({ fooBar: 1 }) }

    context "with a stored key" do
      it "reports the reader as available" do
        expect(store).to respond_to(:fooBar)
      end
    end

    context "with the alternate case of a stored key" do
      it "reports the alternate reader as available" do
        expect(store).to respond_to(:foo_bar)
      end
    end

    context "with an unset key" do
      it "reports the reader as unavailable" do
        expect(store).not_to respond_to(:missing)
      end

      it "still answers a method read with a nil-like child" do
        expect(store.missing.nil?).to be true
      end
    end

    context "with a setter name" do
      it "reports the writer as available" do
        expect(store).to respond_to(:anything=)
      end
    end

    context "when the store is frozen" do
      before { store.freeze }

      context "with a setter name" do
        it "reports the writer as unavailable" do
          expect(store).not_to respond_to(:anything=)
        end
      end
    end
  end

  describe "a field named like a built-in method" do
    let(:store) { described_class.new({ size: 99 }) }

    it "answers the method call with the built-in behavior" do
      expect(store.size).to eq 1
    end

    it "answers a bracket read with the stored value" do
      expect(store[:size]).to eq 99
    end

    it "renders the field in the hash conversion" do
      expect(store.to_h).to eq({ size: 99 })
    end

    it "exposes the field to pattern matching" do
      store => { size: }
      expect(size).to eq 99
    end

    context "when the shadowed key is written through brackets" do
      it "stores the value under the shadowed key" do
        expect { store[:size] = 5 }.to(change { store[:size] }.from(99).to(5))
      end
    end
  end
end
