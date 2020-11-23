# frozen_string_literal: true

source 'https://rubygems.org'
ruby '>= 2.5.0'

group :development do
  gem 'dotenv', '~> 2.7', require: 'dotenv/load'
  gem 'rake', '~> 13.0', require: false
end

group :test do
  gem 'minitest', '~> 5.14', require: 'minitest/autorun'
  gem 'minitest-ci', '~> 3.4', require: false
  gem 'minitest-reporters', '~> 1.4'
  gem 'mocha', '~> 1.11', require: 'mocha/minitest'
  gem 'simplecov', '~> 0.19', require: false
  gem 'webmock', '~> 3.10', require: 'webmock/minitest'
end

group :development, :test do
  gem 'pry-byebug'
end
