# frozen_string_literal: true

require 'entities/pull_request'

module DataSource
  class PullRequests
    attr_reader :client
    private :client

    def initialize(client:)
      @client = client
    end

    def user_pulls
      client.user_pulls.map do |result|
        Entities::PullRequest.new(
          result.slice(:id, :number, :title, :html_url)
        )
      end
    end
  end
end
