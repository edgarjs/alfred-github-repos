# frozen_string_literal: true

require 'json'

module Commands
  class Search
    def self.help
      'Usage: cli search <query>'
    end

    def initialize(repositories:)
      @repositories = repositories
    end

    def call(args)
      results = search(args.join(" "))
      serialize(results)
    end

    private

    attr_reader :repositories

    def search(query)
      query = query.to_s.strip
      return [] if query.empty?

      repositories.search(query: query)
    end

    def serialize(results)
      JSON.generate(items: results.map(&:as_alfred_item))
    end
  end
end
