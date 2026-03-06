desc "Run performance benchmarks (requires benchmark-ips gem, optionally hashie gem)"
task :benchmark do
  ruby "--yjit", "benchmark/compare.rb"
end
