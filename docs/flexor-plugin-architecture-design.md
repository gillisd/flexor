# Flexor Plugin Architecture Design

How to apply the Sequel/Roda plugin pattern from *Polished Ruby Programming* to Flexor.

---

## Why a plugin system

The current flex_keys implementation threads `@flex_keys` through `initialize`, `vivification`, `serialization`, and every key-accepting method with conditional logic. Adding a second feature (globbing paths, key prefixing, etc.) would require the same surgery across the same files. Each new feature multiplies the conditionals.

The plugin pattern eliminates this. Each feature is a self-contained module. The base class is unaware of any feature. Features compose through Ruby's method lookup chain. No conditionals.

---

## The architecture

### Core as a plugin

Following Evans' principle: move ALL Flexor behavior into a `Core` plugin. The `Flexor` class body becomes minimal — just the plugin dispatcher and nested class definitions.

```ruby
class Flexor
  PLUGINS = {}

  def self.register_plugin(symbol, mod)
    PLUGINS[symbol] = mod
  end

  def self.plugin(mod, ...)
    mod = PLUGINS.fetch(mod) if mod.is_a?(Symbol)
    mod.before_load(self, ...) if mod.respond_to?(:before_load)

    include(mod::StoreMethods)      if defined?(mod::StoreMethods)
    extend(mod::ClassMethods)       if defined?(mod::ClassMethods)

    mod.after_load(self, ...)  if mod.respond_to?(:after_load)
    nil
  end

  plugin(Plugins::Core)
end
```

Why "StoreMethods" instead of "InstanceMethods": Flexor is a store. The name describes the domain, not the mechanism. A developer reading `StoreMethods` knows these methods operate on the key-value store.

### The Core plugin

Everything currently in `Flexor`'s class body moves here:

```ruby
module Flexor::Plugins::Core
  module StoreMethods
    def initialize(hash = {}, root: true)
      raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

      @root  = root
      @store = vivify(hash)
    end

    def [](key)
      @store[key]
    end

    def []=(key, value)
      @store[key] = vivify_value(value)
    end

    def set_raw(key, value)
      @store[key] = value
    end

    def delete(key)
      @store.delete(key)
    end

    # ... all other instance methods: to_h, to_s, inspect, merge!,
    # merge, ==, nil?, method_missing, etc.
  end

  module ClassMethods
    def [](input = {})
      case input
      when String then from_json(input)
      when Hash then new(input)
      else raise ArgumentError, "expected a String or Hash, got #{input.class}"
      end
    end

    def from_json(json)
      require "json"
      JSON.parse(json, symbolize_names: true)
          .then { new(it) }
    end
  end

  Flexor.register_plugin(:core, self)
end
```

Note: `[]`, `[]=`, `delete`, etc. are plain methods with no conditional logic. They operate directly on `@store`. This is the base layer that plugins override via `super`.

### The flex_keys plugin

```ruby
module Flexor::Plugins::FlexKeys
  module StoreMethods
    def [](key)
      super(resolve_flex_key(key))
    end

    def []=(key, value)
      super(resolve_flex_key(key), value)
    end

    def set_raw(key, value)
      super(resolve_flex_key(key), value)
    end

    def delete(key)
      super(resolve_flex_key(key))
    end

    def key?(key)
      super(resolve_flex_key(key))
    end

    def deconstruct_keys(keys)
      return super if keys.nil?

      keys.each_with_object({}) do |key, hash|
        resolved = resolve_flex_key(key)
        hash[key] = @store[resolved] if @store.key?(resolved)
      end
    end

    private

    def resolve_flex_key(key)
      return key if @store.key?(key)
      return key unless key.is_a?(Symbol)

      alt = CaseConversion.case_counterpart(key)
      alt && @store.key?(alt) ? alt : key
    end

    def read_via_method(name)
      resolved = resolve_flex_key(name)
      cache_getter(name) if !frozen? && @store.key?(resolved)
      self[name]
    end
  end

  Flexor.register_plugin(:flex_keys, self)
end
```

No `@flex_keys` boolean. No conditionals. The module's presence in the ancestor chain IS the behavior. Each method calls `super` to delegate to `Core::StoreMethods` (or whatever plugin is below it in the chain).

### Loading plugins

```ruby
# Default Flexor loads core + flex_keys:
class Flexor
  plugin(:core)
  plugin(:flex_keys)
end

# Or users can subclass for custom configurations:
class MyStore < Flexor
  plugin(:globbing)  # hypothetical future plugin
end
```

### How plugins compose

When both `Core` and `FlexKeys` are loaded:

```
store[:foo_bar]
  -> FlexKeys::StoreMethods#[]     (resolve_flex_key(:foo_bar) -> :fooBar)
  -> super(:fooBar)
  -> Core::StoreMethods#[]         (@store[:fooBar])
```

When a third plugin (e.g., `Globbing`) is added:

```
store["users.*.name"]
  -> Globbing::StoreMethods#[]     (expand glob)
  -> super for each match
  -> FlexKeys::StoreMethods#[]     (resolve case)
  -> super
  -> Core::StoreMethods#[]         (@store[key])
```

Each plugin in the chain handles its concern and delegates via `super`. No plugin knows about any other plugin. Composition is automatic through Ruby's method lookup.

---

## Plugin conventions

### Module naming

Each plugin is a module under `Flexor::Plugins` containing:

| Submodule | Purpose | Applied via |
|-----------|---------|-------------|
| `StoreMethods` | Instance methods on Flexor | `include` |
| `ClassMethods` | Class methods on Flexor | `extend` |

### Lifecycle hooks

| Hook | Signature | When | Purpose |
|------|-----------|------|---------|
| `before_load(flexor_class, ...)` | Module method | Before inclusion | Declare dependencies |
| `after_load(flexor_class, ...)` | Module method | After inclusion | Initialize class-level state |

Example — a plugin that depends on flex_keys:

```ruby
module Flexor::Plugins::SmartMerge
  def self.before_load(flexor_class)
    flexor_class.plugin(:flex_keys)
  end

  module StoreMethods
    def merge!(other)
      # enhanced merge that resolves keys
      super
    end
  end

  Flexor.register_plugin(:smart_merge, self)
end
```

### Registration

Plugins self-register at the bottom of their module definition:

```ruby
Flexor.register_plugin(:flex_keys, self)
```

This enables symbol-based loading: `Flexor.plugin(:flex_keys)` and autoloading via `require "flexor/plugins/flex_keys"`.

---

## Vivification

Vivification creates child Flexor instances. Since plugins are loaded at the class level (via `include`), every instance of the class gets the same plugins. No propagation needed.

```ruby
def vivify_value(value)
  case value
  when Hash then self.class.new(value, root: false)
  when Array then vivify_array(value)
  else value
  end
end
```

`self.class.new` creates instances of the same class (or subclass), which already has all plugins included. No `flex_keys:` parameter, no `@flex_keys` variable, no per-instance configuration.

---

## Serialization

Serialization goes back to its simplest form:

```ruby
module Serialization
  def marshal_dump
    { store: to_h, root: @root }
  end

  def marshal_load(data)
    @root  = data[:root]
    @store = vivify(data[:store])
  end
end
```

Since plugins are loaded at the class level, deserialized instances automatically get the same plugins as any other instance. No plugin state needs to be serialized.

If a plugin introduces state that needs persistence (e.g., a configuration hash), it overrides `marshal_dump`/`marshal_load` via `super`:

```ruby
module SomePlugin::StoreMethods
  def marshal_dump
    super.merge(some_plugin_config: @config)
  end

  def marshal_load(data)
    @config = data.delete(:some_plugin_config)
    super
  end
end
```

Each plugin is responsible for its own state. The base serialization doesn't need to know about any plugin.

---

## Subclass isolation

Following Evans' pattern, `inherited` creates fresh subclass copies so different applications can load different plugin sets:

```ruby
class Flexor
  def self.inherited(subclass)
    # Subclass starts with same plugins as parent
    # but can load additional plugins independently
  end
end

class APIStore < Flexor
  plugin(:flex_keys)
end

class ConfigStore < Flexor
  # No flex_keys — just core
end
```

Since plugins are `include`d into the class, subclasses inherit parent's plugins but can add their own without affecting the parent.

---

## Freeze after setup

```ruby
class APIStore < Flexor
  plugin(:flex_keys)
  plugin(:globbing)
  freeze
end
```

After loading all plugins and configuring, freeze the class. No more plugins can be loaded, no more monkey-patching. Instances remain mutable.

---

## File structure

```
lib/
  flexor.rb                    # Minimal: plugin dispatcher, register_plugin, PLUGINS hash
  flexor/
    plugins/
      core.rb                  # StoreMethods + ClassMethods — all base behavior
      flex_keys.rb             # StoreMethods overriding key access
    case_conversion.rb         # Pure utility module (unchanged)
    version.rb
  f.rb                         # F = Flexor alias
```

The `plugins/` directory is the extension point. Each file is a self-contained plugin. Adding a new feature means adding a new file — no existing files are modified.

---

## How a future globbing plugin would look

```ruby
module Flexor::Plugins::Globbing
  module StoreMethods
    def dig_glob(*path)
      # Traverse nested Flexor structure matching glob patterns
      # e.g., store.dig_glob("users", "**", "email")
    end

    def [](key)
      if key.is_a?(String) && key.include?("*")
        dig_glob(*key.split("."))
      else
        super
      end
    end
  end

  Flexor.register_plugin(:globbing, self)
end
```

It follows the same pattern: override `[]`, handle its concern, call `super` for everything else. No modification to `Core`, `FlexKeys`, or any existing code.

---

## What changes from the current implementation

| Aspect | Current | Plugin architecture |
|--------|---------|-------------------|
| Core behavior | Defined in `Flexor` class body | `Flexor::Plugins::Core::StoreMethods` module |
| flex_keys | `@flex_keys` boolean + `resolve_key` conditionals | `Flexor::Plugins::FlexKeys::StoreMethods` + `super` |
| Vivification | Propagates `flex_keys: @flex_keys` | Just `self.class.new` — plugins are class-level |
| Serialization | Stores/restores `@flex_keys` | No plugin awareness — back to `{ store:, root: }` |
| Adding new features | Modify 4+ existing files, add conditionals | Add one file in `plugins/`, zero changes to existing code |
| Method dispatch (flex_keys off) | `resolve_key` called, returns key unchanged | Method not in chain — zero overhead |

---

## Design principles applied

From *Polished Ruby Programming*:

1. **Core as a plugin** — all behavior in modules, nothing in the class body
2. **super as composition** — plugins chain through method lookup
3. **No conditionals for feature presence** — the module's presence IS the feature
4. **Hooks for lifecycle** — before_load/after_load for setup and dependencies
5. **Symbol registration** — lazy loading, clean API
6. **Subclass isolation** — different apps, different plugin sets
7. **Globally frozen, locally mutable** — freeze after setup
