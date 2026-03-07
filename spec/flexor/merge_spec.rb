RSpec.describe Flexor do
  describe "#merge" do
    it "returns a new Flexor with the merged contents" do
      a = described_class.new({ x: 1 })
      b = a.merge({ y: 2 })
      expect(b.to_h).to eq({ x: 1, y: 2 })
    end

    it "does not modify the original" do
      a = described_class.new({ x: 1 })
      a.merge({ y: 2 })
      expect(a.to_h).to eq({ x: 1 })
    end

    it "overwrites scalar values" do
      a = described_class.new({ x: 1 })
      b = a.merge({ x: 99 })
      expect(b.x).to eq 99
    end

    it "deep merges nested hashes" do
      a = described_class.new({ db: { host: "localhost", port: 5432 } })
      b = a.merge({ db: { port: 3306, name: "mydb" } })
      expect(b.db.host).to eq "localhost"
      expect(b.db.port).to eq 3306
      expect(b.db.name).to eq "mydb"
    end

    it "deep merges multiple levels" do
      a = described_class.new({ a: { b: { c: 1, d: 2 } } })
      b = a.merge({ a: { b: { d: 3, e: 4 } } })
      expect(b.a.b.c).to eq 1
      expect(b.a.b.d).to eq 3
      expect(b.a.b.e).to eq 4
    end

    it "replaces a nested subtree with a scalar when incoming is scalar" do
      a = described_class.new({ x: { nested: true } })
      b = a.merge({ x: "flat" })
      expect(b.x).to eq "flat"
    end

    it "replaces a scalar with a nested hash" do
      a = described_class.new({ x: "flat" })
      b = a.merge({ x: { nested: true } })
      expect(b.x.nested).to be true
    end

    it "accepts a Flexor as argument" do
      a = described_class.new({ x: 1 })
      b = described_class.new({ y: 2 })
      c = a.merge(b)
      expect(c.to_h).to eq({ x: 1, y: 2 })
    end

    it "vivifies hashes in the merged result" do
      a = described_class.new({ x: 1 })
      b = a.merge({ config: { db: "pg" } })
      expect(b.config).to be_a described_class
      expect(b.config.db).to eq "pg"
    end
  end

  describe "#merge!" do
    it "modifies the receiver in place" do
      a = described_class.new({ x: 1 })
      a.merge!({ y: 2 })
      expect(a.to_h).to eq({ x: 1, y: 2 })
    end

    it "returns self" do
      a = described_class.new({ x: 1 })
      result = a.merge!({ y: 2 })
      expect(result).to equal a
    end

    it "deep merges nested hashes in place" do
      a = described_class.new({ db: { host: "localhost", port: 5432 } })
      a.merge!({ db: { port: 3306 } })
      expect(a.db.host).to eq "localhost"
      expect(a.db.port).to eq 3306
    end

    it "accepts a Flexor as argument" do
      a = described_class.new({ x: 1 })
      b = described_class.new({ y: 2, z: 3 })
      a.merge!(b)
      expect(a.to_h).to eq({ x: 1, y: 2, z: 3 })
    end
  end
end
