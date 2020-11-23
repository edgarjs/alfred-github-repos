# frozen_string_literal: true

require 'entities/repository'

module DataSource
  class Repositories
    attr_reader :client
    private :client

    def initialize(client:)
      @client = client
    end

    def search(params)
      return [] unless params[:query]

      deserialize(client.search_repos(params))
    end

    def user_repos
      deserialize(client.user_repos)
    end

    private

    def deserialize(results)
      results.map do |result|
        Entities::Repository.new(
          result.slice(:id, :name, :full_name, :html_url, :ssh_url)
        )
      end
    end
  end
end
