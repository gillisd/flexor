require_relative "lib/flexor/version"

Gem::Specification.new do |spec|
  spec.name = "flexor"
  spec.version = Flexor::VERSION
  spec.authors = ["David Gillis"]
  spec.email = ["david@flipmine.com"]
  spec.summary = "A Hash-like data store that does what you tell it to do"
  spec.description = "Flexor provides autovivifying nested access, nil-safe chaining, " \
                     "and seamless conversion between hashes and method-style access. " \
                     "Built for flexible data containers, middleware state, and prototyping."
  spec.homepage = "https://github.com/gillisd/flexor"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  gemspec_file = File.basename(__FILE__)
  files = IO.popen(["git", "ls-files", "-z"], chdir: __dir__, err: IO::NULL) { |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec_file) ||
        f.start_with?("bin/", "test/", "spec/", "features/", ".git", "Gemfile")
    end
  }
  files = Dir.glob("{lib,exe,rakelib}/**/*").push("README.md", "LICENSE.txt", "Rakefile") if files.empty?
  spec.files = files
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
end
