require 'debug'
RSpec.describe Flexor do
  it "has a version number" do
    expect(Flexor::VERSION).not_to be_nil
  end

  describe 'getting a level 1 property via method' do
    subject { Flexor.new({foo: "bar"}) }

    it 'reads the property' do
      expect(subject.foo).to eq "bar"
    end
  end

  describe 'getting a level 1 property via hash accessor' do
    subject { Flexor.new({foo: "bar"}) }

    it 'reads the property' do
      expect(subject[:foo]).to eq "bar"
    end
  end

  describe "setting a level 1 property" do
    it "sets the property" do
      expect(subject.foo).to be_nil
      subject.foo = "bar"
      expect(subject.foo).to eq "bar"
   end
  end

  describe "setting a level 2 property via method" do
    context "the level one property has been set" do
      it 'sets the property' do
        subject.rank.first = 1
        expect(subject.rank.third).to be_nil
        subject.rank.third = 3
        expect(subject.rank.third).to eq 3
      end
    end

    context "the level 1 property has not been set" do
      it 'sets the property' do
        expect(subject.rank).to be_nil
        subject.rank.first = 1
        expect(subject.rank.first).to eq 1
      end
    end
  end

  describe "setting a level 2 property via hash accessor" do
    context "the level one property has been set" do
      it 'sets the property' do
        subject[:rank][:first] = 1
        expect(subject[:rank][:third]).to be_nil
        subject[:rank].third = 3
        expect(subject[:rank][:third]).to eq 3
      end
    end

    context "the level 1 property has not been set" do
      it 'sets the property' do
        expect(subject.rank).to be_nil
        subject.rank.first = 1
        expect(subject.rank.first).to eq 1
      end
    end
  end
end
