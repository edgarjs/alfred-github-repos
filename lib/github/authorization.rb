# frozen_string_literal: true

require 'local_storage'

module Github
  class Authorization
    class NotAuthorizedError < StandardError; end

    AUTHORIZATION_URL = 'https://github.com/settings/tokens/new?description=Github%20Repos&scopes=repo'.freeze
    CREDENTIALS = '~/.github-repos/config'.freeze

    attr_reader :username, :token

    def initialize(username, token)
      @username = username
      @token = token
    end

    class << self
      def authorize!
        auth = credentials.get || raise(NotAuthorizedError)

        new(auth[:username], auth[:token])
      end

      def store_credentials(username, token)
        credentials.put(
          username: username,
          token: token
        )
      end

      def stored?
        !credentials.get.nil?
      end

      private

      def credentials
        LocalStorage.new(CREDENTIALS)
      end
    end
  end
end
