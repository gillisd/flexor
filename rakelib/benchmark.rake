desc "Run performance benchmarks (optionally install hashie gem for comparison)"
task :benchmark do
  ruby "--yjit", "-rbundler/setup", "benchmark/compare.rb"
end
