require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

namespace :zeitwerk do
  desc "Verify all files follow Zeitwerk naming conventions"
  task :validate do
    ruby "-e", <<~RUBY
      require 'flexor'
      Flexor::LOADER.eager_load(force: true)
      puts 'Zeitwerk: All files loaded successfully.'
    RUBY
  end
end

task default: [:spec, :rubocop]
