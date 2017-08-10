#!/usr/bin/env rake

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

desc 'Run rubocop style checks'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb'] # Only library code.
end

desc 'Run unit tests'
RSpec::Core::RakeTask.new(:unit) do |task|
  task.pattern = 'spec/*_spec.rb'
end

# Default
desc 'Run style and unit tests'
task default: %w(rubocop unit)
