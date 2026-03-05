# Benchmark: Flexor vs Hashie::Mash vs OpenStruct

Ruby 4.0.1, YJIT enabled, aarch64-linux

Flexor 0.0.1 | Hashie 5.1.1 | OpenStruct (stdlib)

## Results (with lazy method caching)

Flexor caches property accessors via `define_singleton_method`. Getters are cached only when the key already exists in the store — autovivified keys skip the caching cost on first access and cache on the second. Setters cache on first use.

| Operation | Flexor | Mash | OpenStruct | Winner |
|-----------|--------|------|------------|--------|
| Construction (flat) | 1.74M i/s | 530K i/s | 124K i/s | **Flexor** 3.3x vs Mash, 14.0x vs OS |
| Construction (nested) | 660K i/s | 216K i/s | 330K i/s | **Flexor** 3.1x vs Mash |
| Read (method) | 10.8M i/s | 3.69M i/s | 19.4M i/s | **OpenStruct** 1.8x vs Flexor |
| Read (nested chain) | 3.76M i/s | 1.43M i/s | — | **Flexor** 2.6x |
| Write (setter) | 6.59M i/s | 717K i/s | 9.97M i/s | **OpenStruct** 1.5x vs Flexor |
| Write (hash assign) | 720K i/s | 426K i/s | — | **Flexor** 1.7x |
| Autovivification | 176K i/s | 270K i/s | — | **Mash** 1.5x |
| to_h (deep) | 547K i/s | 15.3M i/s | 6.6M i/s | **Mash** 28x vs Flexor |
| Deep merge | 1.50M i/s | 181K i/s | — | **Flexor** 8.3x |
| Missing key access | 10.5M i/s | 1.32M i/s | — | **Flexor** 8.0x |

## Method caching evolution

| Operation | No caching | Eager caching | Lazy caching |
|-----------|-----------|--------------|-------------|
| Read (method) | 3.76M | 10.1M | **10.8M** |
| Read (nested chain) | 1.32M | 3.69M | **3.76M** |
| Write (setter) | 1.27M | 6.79M | **6.59M** |
| Missing key access | 3.79M | 10.9M | **10.5M** |
| Autovivification | **291K** | 71K (4x regression) | 176K (2.5x recovered) |

Lazy caching keeps all the read/write speedups (2.7-5.3x faster than no caching) while recovering most of the autovivification regression (from 4x slower to 1.5x slower vs Mash).

## Analysis

### Why Flexor wins construction and merge

Flexor's wrapper design is lighter at construction time. Creating a Flexor means building an autovivifying Hash via `default_proc` and iterating the input — no key conversion, no warning checks, no indifferent access setup. Mash converts every key to a string, checks for method collisions, and sets up its indifferent access layer.

Deep merge is 8.3x faster because Flexor's `merge` does a `dup` + recursive `merge!`, while Mash's merge goes through its full `deep_update` pipeline with key conversion at every level.

### Why Flexor is close to OpenStruct on reads and writes

With method caching, Flexor uses the same strategy as OpenStruct: `define_singleton_method` on first access, direct method call thereafter. The remaining 1.8x gap on reads comes from Flexor's cached method delegating through `self[name]` → `@store[name]` (two method calls) vs OpenStruct's direct `@table[:name]` (one ivar access).

### Why Mash wins to_h

Mash IS a Hash (`Mash < Hash`), so `to_h` is essentially a no-op — it returns itself or a thin copy. Flexor wraps a Hash and must recursively convert every nested Flexor back to a plain Hash, filtering phantom keys along the way. This is the main cost of the wrapper design.

For most use cases this doesn't matter — you call `to_h` at serialization boundaries, not in hot loops.

### How lazy caching works

The key insight: only cache getters when `@store.key?(name)` is true. On first access to an unset key, autovivification creates the key via `default_proc` but no singleton method is defined. On the second access, the key exists, so the method gets cached. Constructor-populated keys cache on first read since they already exist in the store.

This means autovivification chains (`store.a.b.c.d = "deep"`) only pay the `define_singleton_method` cost for the final setter, not the intermediate getters. Short-lived Flexors created during chain construction are never burdened with cached methods.

## Methodology

Benchmarks use `benchmark-ips` which measures iterations per second over a 5-second window with warmup. Each operation is tested in isolation. OpenStruct is excluded from operations it doesn't support (nested chaining, autovivification, merge, missing key handling).

Run: `ruby --yjit benchmark/compare.rb`
