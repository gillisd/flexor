class Flexor
  ##
  # Namespace for Flexor plugins. Each plugin is a module containing
  # optional +StoreMethods+ and +ClassMethods+ submodules.
  module Plugins
    ##
    # Class-level methods for registering and loading plugins.
    # Extended onto Flexor to provide +.plugin+ and +.register_plugin+.
    module Dispatcher
      def register_plugin(symbol, mod)
        Flexor.plugin_registry[symbol] = mod
      end

      def plugin(mod, ...)
        mod = resolve_plugin(mod)
        mod.before_load(self, ...) if mod.respond_to?(:before_load)

        include(mod::StoreMethods) if defined?(mod::StoreMethods)
        extend(mod::ClassMethods)  if defined?(mod::ClassMethods)

        mod.after_load(self, ...) if mod.respond_to?(:after_load)
        nil
      end

      def plugin_registry
        @plugin_registry ||= {}
      end

      private

      def resolve_plugin(mod)
        return mod unless mod.is_a?(Symbol)

        Flexor.plugin_registry.fetch(mod)
      end
    end
  end
end
