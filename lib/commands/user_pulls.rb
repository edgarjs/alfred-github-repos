# frozen_string_literal: true

require 'json'

module Commands
  class UserPulls
    def self.help
      'Usage: cli user-pulls [query]'
    end

    def initialize(pull_requests:)
      @pull_requests = pull_requests
    end

    def call(args)
      results = filter_pulls(args.join(" "))
      serialize(results)
    end

    private

    attr_reader :pull_requests

    def filter_pulls(query)
      query = query.to_s.strip
      return user_pulls if query.empty?

      filter = Regexp.new(query.split('').join('.*'))
      user_pulls.select do |pull|
        filter =~ pull.title || filter =~ pull.html_url
      end
    end

    def user_pulls
      pull_requests.user_pulls
    end

    def serialize(results)
      JSON.generate(items: results.map(&:as_alfred_item))
    end
  end
end
