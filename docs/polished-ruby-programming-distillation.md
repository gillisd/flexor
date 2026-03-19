# Polished Ruby Programming: Plugin Architecture Distillation

Notes from *Polished Ruby Programming* by Jeremy Evans (Packt, 2021). Evans is a Ruby committer and the author of Sequel and Roda, two libraries whose plugin systems are considered reference implementations.

---

## The Plugin System (Chapter 8)

Chapter 8 builds a plugin system through 9 progressive versions. The domain is a library management system (`Libry`) with `Book` and `User` classes.

### Version 1: Basic plugin with include

The starting point. Core behavior lives in a module, not in the class body. The `plugin` class method inspects a module for named submodules and includes them:

```ruby
class Libry
  class Book; end
  class User; end

  module Plugins
    module Core
      module BookMethods
        attr_accessor :checked_out_to

        def initialize(name)
          @name = name
        end

        def checkin
          checked_out_to.books.delete(self)
          @checked_out_to = nil
        end
      end

      module UserMethods
        attr_accessor :books

        def initialize(id)
          @id = id
          @books = []
        end

        def checkout(book)
          book.checked_out_to = self
          @books << book
        end
      end
    end
  end

  def self.plugin(mod)
    if defined?(mod::BookMethods)
      Book.include(mod::BookMethods)
    end
    if defined?(mod::UserMethods)
      User.include(mod::UserMethods)
    end
    nil
  end

  plugin(Plugins::Core)
end
```

**Critical design decision:** Core behavior is a plugin, not direct class methods. This means every method is overridable by subsequent plugins through the same `include` mechanism. If core methods were defined directly in the class body, included modules could not override them (class methods take precedence over included module methods in Ruby's lookup chain).

### Version 2: Plugin composition via super

A `Cursing` plugin demonstrates how plugins compose. Each plugin's methods call `super` to delegate to the previous layer:

```ruby
module Libry::Plugins::Cursing
  module BookMethods
    def curse!
      @cursed = true
    end

    def checked_out_to=(user)
      user.curse! if @cursed
      super
    end
  end

  module UserMethods
    def curse!
      @cursed = true
    end

    def checkout(book)
      super unless @cursed
    end
  end
end

Libry.plugin(Libry::Plugins::Cursing)
```

`super` is the composition mechanism. Each plugin in the method lookup chain chooses whether to call previous behavior or not.

### Version 3: Class methods via extend

Adds `BookClassMethods`/`UserClassMethods` support:

```ruby
def self.plugin(mod)
  Book.include(mod::BookMethods)  if defined?(mod::BookMethods)
  User.include(mod::UserMethods)  if defined?(mod::UserMethods)
  Book.extend(mod::BookClassMethods) if defined?(mod::BookClassMethods)
  User.extend(mod::UserClassMethods) if defined?(mod::UserClassMethods)
end
```

`include` adds instance methods. `extend` adds class methods. Same mechanism, different target.

### Version 4: after_load hook

Problem: a `Tracking` plugin needs to initialize `@tracked` on the class after inclusion. Solution: a lifecycle hook:

```ruby
def self.plugin(mod)
  # ... include/extend ...
  mod.after_load if mod.respond_to?(:after_load)
end

module Libry::Plugins::Tracking
  def self.after_load
    [Libry::Book, Libry::User].each do |klass|
      klass.instance_exec { @tracked ||= [] }
    end
  end
end
```

### Version 5-6: before_load for dependencies

An `AutoCurse` plugin needs `Cursing` loaded first:

```ruby
def self.plugin(mod)
  mod.before_load if mod.respond_to?(:before_load)
  # ... include/extend ...
  mod.after_load  if mod.respond_to?(:after_load)
end

module Libry::Plugins::AutoCurse
  def self.before_load
    Libry.plugin(Libry::Plugins::Cursing)
  end
end
```

`before_load` fires before module inclusion, ensuring dependencies are in the method chain before the dependent plugin adds its own layer on top.

### Version 7: Symbol-based registration

Plugins self-register so they can be loaded by symbol:

```ruby
class Libry
  PLUGINS = {}

  def self.register_plugin(symbol, mod)
    PLUGINS[symbol] = mod
  end

  def self.plugin(mod)
    mod = PLUGINS.fetch(mod) if mod.is_a?(Symbol)
    # ...
  end
end

module Libry::Plugins::Cursing
  # ... plugin code ...
  Libry.register_plugin(:cursing, self)
end
```

Enables `Libry.plugin(:cursing)` and pairs with `require "libry/plugins/#{mod}"` for autoloading.

### Version 8: Subclass isolation via inherited

Each subclass gets its own nested class copies:

```ruby
def self.inherited(subclass)
  subclass.const_set(:Book, Class.new(self::Book))
  subclass.const_set(:User, Class.new(self::User))
end
```

Critical change: `Book.include` becomes `self::Book.include`. Plugins applied to a subclass only affect that subclass.

### Version 9: Configurable plugins

Plugins receive arguments and blocks:

```ruby
def self.plugin(mod, ...)
  mod.before_load(self, ...) if mod.respond_to?(:before_load)
  # ... include/extend ...
  mod.after_load(self, ...)  if mod.respond_to?(:after_load)
end

# Usage:
Libry.plugin(:tracking) do |obj|
  puts "Tracked: #{obj}"
end
```

The `...` (Ruby 2.7+ forwarding) passes all arguments and block to the hooks.

---

## Module Patterns: include, extend, prepend

| Mechanism | Methods become | Applied to | super calls |
|-----------|---------------|------------|-------------|
| `include` | Instance methods | All instances | Previous include in chain |
| `extend` | Singleton methods | Specific object or class | Previous extend in chain |
| `prepend` | Instance methods (before class) | All instances | The class's own method |

**Why the plugin system uses `include` over `prepend`:**

Plugins compose by including modules. Most-recently-included goes first in the lookup chain. `super` chains naturally through each plugin's layer. `prepend` is used for wrapping (decorator pattern), not for composable plugins.

**`extend` on an object** is equivalent to `include` on that object's singleton class. Used for per-object decoration:

```ruby
module Cursed::Book
  def checked_out_to=(user)
    user.extend(Cursed::User)
    super
  end
end

book.extend(Cursed::Book)  # only this book is cursed
```

**`prepend` for wrapping** (Chapter 9 — Memomer):

```ruby
module Memomer
  def self.extended(klass)
    mod = Module.new
    klass.prepend(mod)
    klass.instance_variable_set(:@memomer_mod, mod)
  end

  def memoize(arg)
    iv = :"@memomer_#{arg}"
    @memomer_mod.define_method(arg) do
      if instance_variable_defined?(iv)
        return instance_variable_get(iv)
      end
      v = super()
      instance_variable_set(iv, v)
      v
    end
  end
end
```

The prepended module wraps the original method: check cache, miss calls `super()` (the real method), store result. The original method is untouched.

---

## Method Lookup Chain

When `user.checkout(book)` is called:

1. Singleton class of `user`
2. Modules extended onto `user` (most recent first)
3. `user`'s class (`Libry::User`)
4. Modules prepended to `Libry::User` (most recent first)
5. Modules included into `Libry::User` (most recent first)
6. Superclass and its chain

When `Libry.plugin(Cursing)` runs `User.include(Cursing::UserMethods)`, Ruby inserts `Cursing::UserMethods` before `Core::UserMethods` in the chain. Cursing's `checkout` runs first and calls `super` to reach Core's `checkout`.

**Key insight:** `include` can override methods from earlier `include` calls, but NOT methods defined directly in the class body. This is why core behavior must be a plugin (module) — if it's defined directly, plugins can't override it.

---

## Hook Methods

### Ruby built-in hooks

| Hook | Fires when | Plugin system use |
|------|-----------|-------------------|
| `Module#included(base)` | Module is included | Auto-extend class methods |
| `Module#extended(base)` | Module is extended | Dynamic setup (Memomer) |
| `Module#prepended(base)` | Module is prepended | Similar to included |
| `Class#inherited(subclass)` | Class is subclassed | Isolated nested classes (V8) |

### Plugin system hooks (custom)

| Hook | Fires when | Purpose |
|------|-----------|---------|
| `before_load(libry, ...)` | Before module inclusion | Declare dependencies |
| `after_load(libry, ...)` | After module inclusion | Initialize state |

Sequel refines this with `apply` (one-time, first load) and `configure` (every call, re-configurable).

---

## Globally Frozen, Locally Mutable

The principle: during setup, keep everything mutable. After setup, freeze classes.

```ruby
class MyLibry < Libry
  plugin(:tracking)

  Book.freeze
  User.freeze
  freeze
end
```

- **Frozen classes** cannot be reopened or monkey-patched at runtime
- **Instances remain mutable** (locally mutable)
- The setup/runtime boundary becomes explicit
- Ruby can optimize frozen class method dispatch

---

## Real-World Examples

### Roda (web framework by Evans)

```ruby
class Roda
  def self.plugin(plugin, *args, &block)
    plugin = RodaPlugins.load_plugin(plugin) if plugin.is_a?(Symbol)
    plugin.load_dependencies(self, *args, &block)
    include plugin::InstanceMethods   if defined?(plugin::InstanceMethods)
    extend plugin::ClassMethods       if defined?(plugin::ClassMethods)
    self::RodaRequest.include plugin::RequestMethods   if defined?(plugin::RequestMethods)
    self::RodaRequest.extend plugin::RequestClassMethods if defined?(plugin::RequestClassMethods)
    self::RodaResponse.include plugin::ResponseMethods  if defined?(plugin::ResponseMethods)
    self::RodaResponse.extend plugin::ResponseClassMethods if defined?(plugin::ResponseClassMethods)
    plugin.configure(self, *args, &block)
  end
end
```

ALL of Roda's core behavior lives in `Roda::RodaPlugins::Base`. The class is empty by default.

### Sequel (database library by Evans)

Same pattern. `Sequel::Model` is itself a plugin — all methods come from `ClassMethods`, `InstanceMethods`, `DatasetMethods` modules. The lifecycle:

1. `apply(model, *args, &block)` — once, before inclusion
2. Module inclusion (include + extend)
3. `configure(model, *args, &block)` — every call, after inclusion

---

## Anti-Patterns

### 1. Boolean flags threading through the codebase

An `@flex_keys` instance variable checked in every method with `return key unless @flex_keys`. This is the opposite of the plugin pattern — it tightly couples the extension into every part of the base class. The plugin pattern eliminates conditionals: the module's presence IS the behavior.

### 2. Core behavior defined directly in the class body

Methods defined in the class body cannot be overridden by included modules. If you want plugins to be able to override any behavior, all behavior must live in modules.

### 3. Singleton methods for shared behavior

Defining behavior directly on individual objects (`def book.method`) is hard to test, discover, and compose. Use modules instead.

### 4. Monkey-patching open classes

Reopening classes affects all instances globally. The plugin system scopes changes to specific applications/subclasses.

### 5. Using method_missing without respond_to_missing?

```ruby
# WRONG — breaks introspection
def method_missing(meth, *)
  @fields.fetch(meth) { super }
end

# CORRECT — maintain the contract
def respond_to_missing?(meth, *)
  @fields.include?(meth)
end
```

### 6. Prefer define_method over method_missing

`method_missing` has performance overhead (Ruby traverses the whole chain before calling it). Use `define_method` when you can enumerate the methods. Reserve `method_missing` for genuinely dynamic dispatch (1000+ possible methods).

---

## Architecture Invariants

1. **The base class is minimal.** Core behavior lives in a Core plugin, not in the class body.
2. **Plugins are modules, not objects.** Named submodules (`BookMethods`, `UserMethods`, `BookClassMethods`). No plugin class hierarchy.
3. **`super` is the composition mechanism.** The method lookup chain through included modules IS the call chain.
4. **Hooks before and after inclusion.** `before_load` for dependencies, `after_load` for initialization.
5. **Symbol registration enables lazy loading.** `plugin(:name)` triggers `require` on demand.
6. **Subclass isolation via `inherited`.** Fresh nested class copies per subclass.
7. **Freeze at end of setup.** Globally immutable, locally mutable.
