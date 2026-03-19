RSpec.describe Flexor do
  describe ".plugin" do
    context "with StoreMethods" do
      let(:mod) do
        Module.new do
          const_set(:StoreMethods, Module.new {
            def test_store_method
              :from_plugin
            end
          })
        end
      end

      it "includes StoreMethods into the target class" do
        test_class = Class.new(described_class)
        test_class.plugin(mod)
        expect(test_class.new.test_store_method).to eq :from_plugin
      end
    end

    context "with ClassMethods" do
      let(:mod) do
        Module.new do
          const_set(:ClassMethods, Module.new {
            def test_class_method
              :from_plugin
            end
          })
        end
      end

      it "extends ClassMethods onto the target class" do
        test_class = Class.new(described_class)
        test_class.plugin(mod)
        expect(test_class.test_class_method).to eq :from_plugin
      end
    end

    context "with before_load callback" do
      it "calls before_load with the class before inclusion" do
        received = nil
        mod = build_callback_plugin(:before_load) { |k| received = k }
        test_class = Class.new(described_class)
        test_class.plugin(mod)
        expect(received).to eq test_class
      end
    end

    context "with after_load callback" do
      it "calls after_load with the class after inclusion" do
        received = nil
        mod = build_callback_plugin(:after_load) { |k| received = k }
        test_class = Class.new(described_class)
        test_class.plugin(mod)
        expect(received).to eq test_class
      end
    end

    context "with a registered symbol name" do
      let(:mod) do
        Module.new do
          const_set(:StoreMethods, Module.new {
            def registered_method
              :works
            end
          })
        end
      end

      before { described_class.register_plugin(:test_plugin, mod) }

      it "resolves the symbol to the registered module" do
        test_class = Class.new(described_class)
        test_class.plugin(:test_plugin)
        expect(test_class.new.registered_method).to eq :works
      end
    end

    context "when StoreMethods is not defined" do
      it "does not raise" do
        mod = Module.new
        test_class = Class.new(described_class)
        expect { test_class.plugin(mod) }.not_to raise_error
      end
    end

    context "when two plugins define the same method" do
      let(:base_plugin) do
        Module.new do
          const_set(:StoreMethods, Module.new {
            def greeting
              "hello"
            end
          })
        end
      end

      let(:wrapper_plugin) do
        Module.new do
          const_set(:StoreMethods, Module.new {
            def greeting
              "#{super} world"
            end
          })
        end
      end

      it "composes via super" do
        test_class = Class.new(described_class)
        test_class.plugin(base_plugin)
        test_class.plugin(wrapper_plugin)
        expect(test_class.new.greeting).to eq "hello world"
      end
    end
  end
end

def build_callback_plugin(callback_name, &block)
  Module.new do
    const_set(:StoreMethods, Module.new)
    define_singleton_method(callback_name, &block)
  end
end
