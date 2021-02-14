# frozen_string_literal: true

require 'json'
require 'ostruct'

module Commands
  class UserPulls
    def self.help
      'Usage: cli user-pulls [query]'
    end

    def initialize(pull_requests:, web_host:)
      @pull_requests = pull_requests
      @web_host = web_host
    end

    def call(args)
      results = filter_pulls(args.join(' '))
      results.unshift(open_pulls_page_item) if args.empty?
      serialize(results)
    end

    private

    attr_reader :pull_requests

    def filter_pulls(query)
      query = query.to_s.strip
      return user_pulls if query.empty?

      filter = Regexp.new(query.split('').join('.*'), Regexp::IGNORECASE)
      user_pulls.select do |pull|
        filter =~ pull.title || filter =~ pull.html_url
      end
    end

    def user_pulls
      pull_requests.user_pulls
    end

    def serialize(items)
      JSON.generate(items: items.map(&:as_alfred_item))
    end

    def open_pulls_page_item
      url = "https://#{@web_host}/pulls"
      OpenStruct.new(
        as_alfred_item: {
          title: 'Open your Pull Requests page...',
          subtitle: url,
          arg: url,
          text: {
            copy: url
          }
        }
      )
    end
  end
end
