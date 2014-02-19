require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'

namespace(:gem) { Bundler::GemHelper.install_tasks }

Rake::TestTask.new :spec do |task|
  task.libs << 'spec'
  task.options = '--verbose' if ENV['VERBOSE']
  task.test_files = FileList['spec/**/*_spec.rb']
end

task :default => :spec
