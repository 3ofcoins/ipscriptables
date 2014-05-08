# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
require 'rubocop/rake_task'

namespace(:gem) { Bundler::GemHelper.install_tasks }

Rake::TestTask.new :spec do |task|
  task.libs << 'spec'
  task.options = '--verbose' if ENV['VERBOSE']
  task.test_files = FileList['spec/**/*_spec.rb']
end

desc 'Run Rubocop'
Rubocop::RakeTask.new(:rubocop) do |t|
  t.fail_on_error = true
  t.patterns = %w(Rakefile bin/* lib/**/*.rb spec/**/*.rb)
end

task :default => [:rubocop, :spec]
