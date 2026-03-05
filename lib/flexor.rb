require "zeitwerk"

module Flexor
  LOADER = Zeitwerk::Loader.for_gem
  LOADER.setup

  class Error < StandardError; end
end
