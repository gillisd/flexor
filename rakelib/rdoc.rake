require "rdoc/task"

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "doc"
  rdoc.title = "Flexor #{Flexor::VERSION}"
  rdoc.rdoc_files.include("README.md", "lib/**/*.rb")
  rdoc.main = "README.md"
end
