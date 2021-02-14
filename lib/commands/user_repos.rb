# frozen_string_literal: true

require 'json'

module Commands
  class UserRepos
    def self.help
      'Usage: cli user-repos [query]'
    end

    def initialize(repositories:)
      @repositories = repositories
    end

    def call(args)
      results = filter_repos(args.join(" "))
      serialize(results)
    end

    private

    attr_reader :repositories

    def filter_repos(query)
      query = query.to_s.strip
      return user_repos if query.empty?

      filter = Regexp.new(query.split('').join('.*'), Regexp::IGNORECASE)
      user_repos.select { |repo| filter =~ repo.full_name }
    end

    def user_repos
      repositories.user_repos
    end

    def serialize(results)
      JSON.generate(items: results.map(&:as_alfred_item))
    end
  end
end
