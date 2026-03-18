RSpec.describe Flexor::CaseConversion do
  describe ".camelize" do
    it "converts single-segment snake_case" do
      expect(described_class.camelize("foo_bar")).to eq "fooBar"
    end

    it "converts multi-segment snake_case" do
      expect(described_class.camelize("foo_bar_baz")).to eq "fooBarBaz"
    end

    it "returns single words unchanged" do
      expect(described_class.camelize("foo")).to eq "foo"
    end

    it "handles numeric segments" do
      expect(described_class.camelize("level_2_boss")).to eq "level2Boss"
    end

    it "produces lowerCamelCase, not UpperCamelCase" do
      expect(described_class.camelize("foo_bar")[0]).to eq "f"
    end
  end

  describe ".underscore" do
    it "converts lowerCamelCase" do
      expect(described_class.underscore("fooBar")).to eq "foo_bar"
    end

    it "converts multi-hump camelCase" do
      expect(described_class.underscore("fooBarBaz")).to eq "foo_bar_baz"
    end

    it "converts consecutive uppercase (acronyms)" do
      expect(described_class.underscore("HTMLParser")).to eq "html_parser"
    end

    it "returns lowercase words unchanged" do
      expect(described_class.underscore("foo")).to eq "foo"
    end

    it "converts dashes to underscores" do
      expect(described_class.underscore("foo-bar")).to eq "foo_bar"
    end
  end

  describe ".alternate_key" do
    it "returns camelCase symbol for snake_case input" do
      expect(described_class.alternate_key(:foo_bar)).to eq :fooBar
    end

    it "returns snake_case symbol for camelCase input" do
      expect(described_class.alternate_key(:fooBar)).to eq :foo_bar
    end

    it "returns nil for lowercase-only keys with no underscores" do
      expect(described_class.alternate_key(:foo)).to be_nil
    end

    it "treats mixed keys as snake_case (underscore takes priority)" do
      expect(described_class.alternate_key(:foo_barBaz)).to eq :fooBarBaz
    end
  end
end
