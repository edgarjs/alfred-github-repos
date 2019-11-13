# frozen_string_literal: true

require 'local_storage'
require 'config_path'

module Github
  class Authorization
    class NotAuthorizedError < StandardError; end

    AUTHORIZATION_URL = 'https://github.com/settings/tokens/new?description=Github%20Repos&scopes=repo'.freeze
    LEGACY_CREDENTIALS = '~/.github-repos/config'.freeze
    CREDENTIALS_FILE_NAME = 'config'.freeze

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
        config_path = ConfigPath.new(CREDENTIALS_FILE_NAME, LEGACY_CREDENTIALS).get
        LocalStorage.new(config_path)
      end
    end
  end
end
