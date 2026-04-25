require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "gempilot/version_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
Gempilot::VersionTask.new

task default: [:spec, :rubocop]
