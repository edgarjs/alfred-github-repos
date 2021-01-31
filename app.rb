# frozen_string_literal: true

$stdout.sync = true
$LOAD_PATH.unshift File.expand_path('lib')

require 'data_source/client/github'
require 'data_source/pull_requests'
require 'data_source/repositories'
require 'commands/help'
require 'commands/search'
require 'commands/user_repos'
require 'commands/user_pulls'

class App
  class << self
    def client
      DataSource::Client::Github.new(
          host: ENV['GITHUB_API_HOST'] || 'api.github.com',
          access_token: ENV['GITHUB_ACCESS_TOKEN'],
          me_account: ENV['GITHUB_ME_ACCOUNT'] || '@me',
          pr_all_involve_me: ENV['PR_ALL_INVOLVE_ME'],
          cache_dir: ENV['alfred_workflow_cache'],
          cache_ttl_sec_repo: (ENV['CACHE_TTL_SEC_REPO'] || (24 * 60 * 60)).to_i,
          cache_ttl_sec_org: (ENV['CACHE_TTL_SEC_ORG'] || (24 * 60 * 60)).to_i,
          cache_ttl_sec_pr: (ENV['CACHE_TTL_SEC_PR'] || (5 * 60)).to_i,
          )
    end

    def repositories
      DataSource::Repositories.new(client: client)
    end

    def pull_requests
      DataSource::PullRequests.new(client: client)
    end

    def help
      Commands::Help.new
    end

    def search
      Commands::Search.new(repositories: repositories)
    end

    def user_repos
      Commands::UserRepos.new(repositories: repositories)
    end

    def user_pulls
      Commands::UserPulls.new(pull_requests: pull_requests)
    end
  end
end
