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

# The 'test' task is used by Travis, at least.
desc 'Run test-related tasks'
task test: %w(rubocop unit)

# Default
desc 'Default to test-related tasks'
task default: 'test'
