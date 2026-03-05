# Benchmark: Flexor vs Hashie::Mash vs OpenStruct

Ruby 4.0.1, YJIT enabled, aarch64-linux

Flexor 0.0.1 | Hashie 5.1.1 | OpenStruct (stdlib)

## Results

| Operation | Flexor | Mash | OpenStruct | Winner |
|-----------|--------|------|------------|--------|
| Construction (flat) | 1.78M i/s | 534K i/s | 128K i/s | **Flexor** 3.3x vs Mash, 13.9x vs OS |
| Construction (nested) | 669K i/s | 217K i/s | 310K i/s | **Flexor** 3.1x vs Mash |
| Read (method) | 3.76M i/s | 4.07M i/s | 19.5M i/s | **OpenStruct** 5x vs both |
| Read (nested chain) | 1.32M i/s | 1.43M i/s | — | **Tied** (1.09x) |
| Write (setter) | 1.27M i/s | 726K i/s | 10.1M i/s | **OpenStruct** 8x vs Flexor |
| Write (hash assign) | 675K i/s | 434K i/s | — | **Flexor** 1.6x |
| Autovivification | 291K i/s | 272K i/s | — | **Tied** (1.07x) |
| to_h (deep) | 552K i/s | 16.1M i/s | 7.3M i/s | **Mash** 29x vs Flexor |
| Deep merge | 1.21M i/s | 184K i/s | — | **Flexor** 6.6x |
| Missing key access | 3.79M i/s | 1.34M i/s | — | **Flexor** 2.8x |

## Analysis

### Why Flexor wins construction and merge

Flexor's wrapper design is lighter at construction time. Creating a Flexor means building an autovivifying Hash via `default_proc` and iterating the input — no key conversion, no warning checks, no indifferent access setup. Mash converts every key to a string, checks for method collisions, and sets up its indifferent access layer.

Deep merge is 6.6x faster because Flexor's `merge` does a `dup` + recursive `merge!`, while Mash's merge goes through its full `deep_update` pipeline with key conversion at every level.

### Why OpenStruct wins reads and writes

OpenStruct defines real methods on the singleton class. After the first access, `ostruct.name` is a direct method call — no `method_missing`, no hash lookup. Flexor and Mash both go through `method_missing` on every call, which is inherently slower.

This matters less than it looks: OpenStruct can't do nested access, autovivification, merging, or safe chaining. It's fast at the one thing it does.

### Why Mash wins to_h

Mash IS a Hash (`Mash < Hash`), so `to_h` is essentially a no-op — it returns itself or a thin copy. Flexor wraps a Hash and must recursively convert every nested Flexor back to a plain Hash, filtering phantom keys along the way. This is the main cost of the wrapper design.

For most use cases this doesn't matter — you call `to_h` at serialization boundaries, not in hot loops. If it does matter, the data is probably better served by a plain Hash or a struct.

### Why reads are close between Flexor and Mash

Both use `method_missing`. Flexor's is simpler (pattern match on name + args), Mash's is more complex (suffix detection, key conversion, collision checks). YJIT optimizes both reasonably well, keeping them within 10% of each other.

## Methodology

Benchmarks use `benchmark-ips` which measures iterations per second over a 5-second window with warmup. Each operation is tested in isolation. OpenStruct is excluded from operations it doesn't support (nested chaining, autovivification, merge, missing key handling).

Run: `ruby --yjit benchmark/compare.rb`
