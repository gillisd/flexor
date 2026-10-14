RSpec.describe Flexor do
  describe "reading an unset key" do
    it "returns a nil-like child"
    it "leaves the key list unchanged"
    it "leaves the size unchanged"
    it "reports the key as absent"
    it "leaves the deconstructed values unchanged"
    it "leaves the hash conversion unchanged"

    context "with a chain of unset keys" do
      it "leaves the key list unchanged"
      it "returns a nil-like child at every depth"
    end

    context "when the unset child is written" do
      it "attaches the child to its parent"
      it "adds the key to the key list"
      it "exposes the written value through the parent"
    end

    context "when the end of an unset chain is written" do
      it "attaches every intermediate child"
      it "renders the full path in the hash conversion"
    end

    context "when two separate reads of one unset key are each written" do
      it "keeps the first write"
      it "keeps the second write"
    end

    context "when the parent is frozen" do
      it "returns a nil-like child"
      it "raises no error"

      context "when the unset child is written" do
        it "raises a frozen error"
      end
    end
  end

  describe "#eql?" do
    context "with a store holding equal contents" do
      it "treats the stores as equal"
    end

    context "with a store holding different contents" do
      it "treats the stores as distinct"
    end

    context "with nested stores holding equal contents" do
      it "treats the nested stores as equal"
    end

    context "with a plain hash holding equal contents" do
      it "treats the hash as distinct"
    end
  end

  describe "#==" do
    context "with a plain hash holding equal contents" do
      it "treats the hash as equal"
    end
  end

  describe "#hash" do
    context "with stores holding equal contents" do
      it "returns the same value"
    end

    context "with stores holding different contents" do
      it "returns different values"
    end

    context "when an unset key has been read" do
      it "keeps its value"
    end

    context "when a key is written" do
      it "changes its value"
    end
  end

  describe "membership in collections" do
    context "with equal stores in an array" do
      it "collapses them under deduplication"
    end

    context "with equal stores as hash keys" do
      it "resolves them to one entry"
      it "keeps the last value written"
    end
  end

  describe "#each" do
    it "yields every key with its value"
    it "yields in insertion order"
    it "returns the store"

    context "without a block" do
      it "returns an enumerator"
    end

    context "when an unset key has been read" do
      it "yields only the written pairs"
    end
  end

  describe "#map" do
    it "returns the block results in insertion order"
  end

  describe "#select" do
    it "returns the matching pairs in an array"
  end

  describe "#respond_to?" do
    context "with a stored key" do
      it "reports the reader as available"
    end

    context "with the alternate case of a stored key" do
      it "reports the alternate reader as available"
    end

    context "with an unset key" do
      it "reports the reader as unavailable"
      it "still answers a method read with a nil-like child"
    end

    context "with a setter name" do
      it "reports the writer as available"
    end

    context "when the store is frozen" do
      context "with a setter name" do
        it "reports the writer as unavailable"
      end
    end
  end

  describe "a field named like a built-in method" do
    it "answers the method call with the built-in behavior"
    it "answers a bracket read with the stored value"
    it "renders the field in the hash conversion"
    it "exposes the field to pattern matching"

    context "when the shadowed key is written through brackets" do
      it "stores the value under the shadowed key"
    end
  end
end
