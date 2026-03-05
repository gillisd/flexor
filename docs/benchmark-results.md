# Benchmark: Flexor vs Hashie::Mash vs OpenStruct

Ruby 4.0.1, YJIT enabled, aarch64-linux

Flexor 0.0.1 | Hashie 5.1.1 | OpenStruct (stdlib)

## Results (with method caching)

Flexor caches property accessors via `define_singleton_method` — first access goes through `method_missing`, subsequent accesses hit the cached method directly.

| Operation | Flexor | Mash | OpenStruct | Winner |
|-----------|--------|------|------------|--------|
| Construction (flat) | 1.72M i/s | 534K i/s | 124K i/s | **Flexor** 3.2x vs Mash, 13.9x vs OS |
| Construction (nested) | 624K i/s | 215K i/s | 253K i/s | **Flexor** 2.9x vs Mash |
| Read (method) | 10.1M i/s | 3.85M i/s | 18.0M i/s | **OpenStruct** 1.8x vs Flexor |
| Read (nested chain) | 3.69M i/s | 1.43M i/s | — | **Flexor** 2.6x |
| Write (setter) | 6.79M i/s | 716K i/s | 9.49M i/s | **OpenStruct** 1.4x vs Flexor |
| Write (hash assign) | 722K i/s | 428K i/s | — | **Flexor** 1.7x |
| Autovivification | 71K i/s | 269K i/s | — | **Mash** 3.8x |
| to_h (deep) | 545K i/s | 15.9M i/s | 7.3M i/s | **Mash** 29x vs Flexor |
| Deep merge | 1.52M i/s | 181K i/s | — | **Flexor** 8.4x |
| Missing key access | 10.9M i/s | 1.29M i/s | — | **Flexor** 8.5x |

## Impact of method caching

| Operation | Before caching | After caching | Change |
|-----------|---------------|---------------|--------|
| Read (method) | 3.76M i/s | 10.1M i/s | **2.7x faster** |
| Read (nested chain) | 1.32M i/s | 3.69M i/s | **2.8x faster** |
| Write (setter) | 1.27M i/s | 6.79M i/s | **5.3x faster** |
| Missing key access | 3.79M i/s | 10.9M i/s | **2.9x faster** |
| Deep merge | 1.21M i/s | 1.52M i/s | 1.25x faster |
| Autovivification | 291K i/s | 71K i/s | **4.1x slower** |

The autovivification regression is the tradeoff: `define_singleton_method` on short-lived objects in tight loops (create Flexor + define 4 methods per iteration) costs more than the caching saves. For the dominant use case — create once, access many times — it's a clear win.

## Analysis

### Why Flexor wins construction and merge

Flexor's wrapper design is lighter at construction time. Creating a Flexor means building an autovivifying Hash via `default_proc` and iterating the input — no key conversion, no warning checks, no indifferent access setup. Mash converts every key to a string, checks for method collisions, and sets up its indifferent access layer.

Deep merge is 8.4x faster because Flexor's `merge` does a `dup` + recursive `merge!`, while Mash's merge goes through its full `deep_update` pipeline with key conversion at every level.

### Why Flexor is close to OpenStruct on reads and writes

With method caching, Flexor uses the same strategy as OpenStruct: `define_singleton_method` on first access, direct method call thereafter. The remaining 1.8x gap on reads comes from Flexor's cached method delegating through `self[name]` → `@store[name]` (two method calls) vs OpenStruct's direct `@table[:name]` (one ivar access).

### Why Mash wins to_h

Mash IS a Hash (`Mash < Hash`), so `to_h` is essentially a no-op — it returns itself or a thin copy. Flexor wraps a Hash and must recursively convert every nested Flexor back to a plain Hash, filtering phantom keys along the way. This is the main cost of the wrapper design.

For most use cases this doesn't matter — you call `to_h` at serialization boundaries, not in hot loops.

### Why autovivification is slower with caching

The autovivification benchmark creates a fresh Flexor and writes 4 levels deep per iteration. Each level triggers `method_missing` which now calls `define_singleton_method` before returning. Since these Flexors are immediately discarded, the caching cost is paid but never recouped. In real usage, you autovivify once and read many times — the caching pays for itself on the second access.

## Methodology

Benchmarks use `benchmark-ips` which measures iterations per second over a 5-second window with warmup. Each operation is tested in isolation. OpenStruct is excluded from operations it doesn't support (nested chaining, autovivification, merge, missing key handling).

Run: `ruby --yjit benchmark/compare.rb`
