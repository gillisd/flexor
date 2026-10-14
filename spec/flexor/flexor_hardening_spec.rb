RSpec.describe Flexor do
  # Anchors: on a store holding a: 1, reading store.phantom.deep leaves keys
  # at [:a], size at 1, key?(:phantom) at false, deconstruct at [1], and to_h
  # at { a: 1 }. The child read back answers nil? with true.
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

    # Anchors: writing x = 1 into the child returned by store.phantom makes
    # store.phantom.x answer 1 and keys answer [:a, :phantom].
    context "when the unset child is written" do
      it "attaches the child to its parent"
      it "exposes the written value through the parent"
    end

    # Anchor: writing store.p.q.r = 1 renders to_h as
    # { a: 1, p: { q: { r: 1 } } }.
    context "when the end of an unset chain is written" do
      it "attaches every intermediate child"
      it "renders the full path in the hash conversion"
    end

    # Anchor: reading store.k twice, then writing x = 1 into the first child
    # and y = 2 into the second, renders store.k.to_h as { x: 1, y: 2 }.
    context "when two separate reads of one unset key are each written" do
      it "keeps the first write"
      it "keeps the second write"
    end

    # REGRESSION: reading a missing key on a frozen store raised FrozenError.
    # Supersedes "autovivification raises on frozen store" in
    # spec/flexor/flexor_freeze_spec.rb, which pins the old behavior.
    # Anchor: the write case raises FrozenError.
    context "when the parent is frozen" do
      it "returns a nil-like child"
      it "raises no error"

      context "when the unset child is written" do
        it "raises a frozen error"
      end
    end
  end

  # Anchors: a store holding x: 1 is eql to another store holding x: 1.
  # Strictness stays Flexor-only: the plain hash { x: 1 } is not eql, while
  # == against that hash stays true.
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

  # Anchors: deduplicating an array of two equal stores leaves one element;
  # a hash keyed by two equal stores holds one entry answering the second
  # value written.
  describe "membership in collections" do
    context "with equal stores in an array" do
      it "collapses them under deduplication"
    end

    context "with equal stores as hash keys" do
      it "resolves them to one entry"
      it "keeps the last value written"
    end
  end

  # Anchors: on { a: 1, b: 2, c: 3 }, each yields [:a, 1], [:b, 2], [:c, 3]
  # in that order; multiplying values by 10 through map returns
  # [[:a, 10], [:b, 20], [:c, 30]]; selecting values above 1 returns
  # [[:b, 2], [:c, 3]]. Enumerable semantics: an Array of pairs.
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
    it "returns the matching pairs"
  end

  # Anchors: on { fooBar: 1 }, the readers fooBar and foo_bar answer true,
  # as does any writer such as anything=. The reader missing answers false,
  # yet a call to the reader missing returns a child whose nil? is true.
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

  # Anchors: on { size: 99 }, size answers 1, store[:size] answers 99,
  # to_h is { size: 99 }, and the pattern { size: 99 } matches.
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
