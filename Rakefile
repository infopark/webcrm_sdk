require "rubygems"
require "bundler/setup"
require 'rspec/core/rake_task'

FileList["./tasks/**/*.rake"].sort.each do |source|
  load source
end

RSpec::Core::RakeTask.new(:spec)

task default: [:build_ca_bundle, :spec]
