# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rules

1. DO NOT edit .rubocop.yml or add inline rubocop exemptions without explicit permission
2. DO NOT run any git command that will rewrite history without explicit permission
3. PREFER method & class extraction over comments
4. Making new files, classes, modules, and methods IS NOT overengineering
5. BEFORE writing code, identify which domain concept owns the behavior. Each class and module should have a single responsibility. If the new behavior doesn't fit an existing class's responsibility, create a new one — don't expand the scope of what's already there.
6. DO NOT name classes with suffixes like "-er" or "-or" unless using a canonical pattern name (e.g., Parser, Router, Controller)
7. ALWAYS write specs first. The workflow is: identify the domain concept (rule 5), write specs describing its behavior, then implement. No implementation without a failing spec.

## Project

Flexor is a Ruby gem providing a Hash-like data store with autovivifying nested access, nil-safe chaining, and seamless conversion between hashes and method-style access. Requires Ruby >= 3.4.

## Commands

- `rake spec` — run all tests
- `bundle exec rspec spec/flexor/flexor_reading_spec.rb` — run a single spec file
- `bundle exec rspec spec/flexor/flexor_reading_spec.rb:15` — run a single example by line
- `rake rubocop` — run linter
- `bundle exec rubocop -a` — autocorrect safe offenses
- `rake` — run both specs and rubocop (default task)
- `rake benchmark` — run performance benchmarks (uses YJIT)
- `rake rdoc` — generate documentation
- `rake version:current` — show current version
- `rake version:bump` — bump patch version
- `bin/console` — IRB session with Flexor loaded

## Architecture

Plugin-based architecture following the Sequel/Roda pattern. `Flexor` class body is a minimal plugin dispatcher. All behavior lives in plugins under `Flexor::Plugins`.

**Plugin dispatcher** (`lib/flexor.rb`):
- `Flexor.plugin(mod)` — includes `mod::StoreMethods`, extends `mod::ClassMethods`
- `Flexor.register_plugin(:name, mod)` — symbol registration for lazy loading
- Lifecycle hooks: `before_load` (dependencies), `after_load` (initialization)
- Plugins compose via Ruby's method lookup chain — each calls `super`

**Plugins:**
- **`Plugins::Core`** (`lib/flexor/plugins/core.rb`) — all base store behavior: autovivifying `@store`, method-style access via `method_missing`, hash delegation, serialization (Marshal/YAML), vivification
- **`Plugins::FlexKeys`** (`lib/flexor/plugins/flex_keys.rb`) — overrides `[]`, `[]=`, `delete`, `key?`, `set_raw`, `deconstruct_keys`, `read_via_method` to resolve camelCase/snake_case alternates before calling `super`

**Utilities:**
- **`CaseConversion`** (`lib/flexor/case_conversion.rb`) — pure `module_function` utilities: `camelize`, `underscore`, `case_counterpart`

Key internals:
- `@store` is the backing Hash with an autovivifying default block
- `@root` flag distinguishes top-level instances from auto-created children (affects `inspect` and `nil?` behavior)
- `method_missing` handles dynamic getter/setter; once accessed, singleton methods are cached for performance (`cache_getter`/`cache_setter`)
- `nil?` returns `true` when `@store` is empty (non-root nodes appear nil-like until written to)
- Adding a new feature means adding a new file in `lib/flexor/plugins/` — no existing files modified

## Style Conventions (from .rubocop.yml)

- Double quotes always (`Style/StringLiterals`)
- No frozen_string_literal comments
- Trailing commas in multiline literals/arguments
- Pipeline-style chaining encouraged (multiline block chains allowed)
- Block length max 8 (keeps blocks small, push logic into pipelines)
- Dot-aligned chaining (`Layout/MultilineMethodCallIndentation: aligned`)
- Consistent 2-space argument indentation (not aligned to first arg)
- Explicit `begin/rescue/end` preferred over implicit method-body rescue
- All classes require rdoc documentation (`Style/Documentation`)
- RSpec: `expect { }.to change { }` block style, nested groups max 4, multiple expectations max 2

## Tests

Specs are organized by concern in `spec/flexor/` (reading, writing, merge, serialization, freeze, etc.). The top-level `spec/flexor_spec.rb` only checks the version. RSpec runs with `--format documentation` and monkey patching disabled.
