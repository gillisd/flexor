require_relative "flexor/version"
require_relative "flexor/plugins"
require_relative "flexor/hash_delegation"
require_relative "flexor/serialization"
require_relative "flexor/vivification"
require_relative "flexor/method_dispatch"
require_relative "flexor/case_conversion"

##
# A Hash-like data store with autovivifying nested access, nil-safe
# chaining, and seamless conversion between hashes and method-style
# access.
class Flexor
  class Error < StandardError; end

  extend Plugins::Dispatcher
end

require_relative "flexor/plugins/core"
require_relative "flexor/plugins/flex_keys"

Flexor.plugin(:core)
Flexor.plugin(:flex_keys)

require_relative "f"
