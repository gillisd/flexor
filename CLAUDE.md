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

Single class `Flexor` in `lib/flexor.rb` with three mixins:

- **`Vivification`** (`lib/flexor/vivification.rb`) — recursively converts Hashes/Arrays into Flexor objects on write; reverses via `recurse_to_h` on read. The `@store` uses a `Hash.new` default block that auto-creates child Flexor nodes (autovivification).
- **`HashDelegation`** (`lib/flexor/hash_delegation.rb`) — delegates `keys`, `values`, `size`, `empty?`, `key?` to `@store`.
- **`Serialization`** (`lib/flexor/serialization.rb`) — Marshal and YAML round-trip support.

Key internals:
- `@store` is the backing Hash with an autovivifying default block
- `@root` flag distinguishes top-level instances from auto-created children (affects `inspect` and `nil?` behavior)
- `method_missing` handles dynamic getter/setter; once accessed, singleton methods are cached for performance (`cache_getter`/`cache_setter`)
- `nil?` returns `true` when `@store` is empty (non-root nodes appear nil-like until written to)

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
