# frozen_string_literal: true

if ENV['TEST_COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    add_filter %r{^/test/}
  end
end

require 'bundler/setup'

Bundler.require(:test)

if ENV['CI']
  require 'minitest/ci'
  Minitest::Ci.report_dir = 'test_results'
end

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new]
