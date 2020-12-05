# frozen_string_literal: true

if ENV['TEST_COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    add_filter %r{^/test/}
  end
end

require 'bundler/setup'

Bundler.require(:test)

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new]
