require "spec_helper"
require "open3"

RSpec.describe Flexor do
  describe "gem loading via require 'flexor'" do
    def run_ruby(code)
      Open3.capture2e("bundle", "exec", "ruby", "-r", "flexor", "-e", code)
    end

    context "when requiring flexor" do
      it "exits successfully using Flexor" do
        _output, status = run_ruby("Flexor.new({ a: 1 })")
        expect(status).to be_success
      end

      it "reads a value via Flexor" do
        output, = run_ruby("puts Flexor.new({ a: 1 }).a")
        expect(output.strip).to eq "1"
      end

      it "exits successfully using F" do
        _output, status = run_ruby("F[a: 1]")
        expect(status).to be_success
      end

      it "F is the same object as Flexor" do
        output, = run_ruby("puts F.equal?(Flexor)")
        expect(output.strip).to eq "true"
      end
    end

    context "when using F[] with JSON" do
      it "parses JSON and allows method access" do
        output, = run_ruby('puts F[%q({"name":"alice"})].name')
        expect(output.strip).to eq "alice"
      end
    end
  end
end
