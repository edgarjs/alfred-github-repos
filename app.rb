# frozen_string_literal: true

$stdout.sync = true
$LOAD_PATH.unshift File.expand_path('lib')

require 'data_source/client/git_hub'
require 'data_source/pull_requests'
require 'data_source/repositories'
require 'commands/help'
require 'commands/search'
require 'commands/user_repos'
require 'commands/user_pulls'

class App
  class << self
    def client
      DataSource::Client::GitHub.new(
        host: ENV['GITHUB_API_HOST'],
        access_token: ENV['GITHUB_ACCESS_TOKEN'],
        me_account: ENV['GITHUB_ME_ACCOUNT'],
        pr_all_involve_me: bool_env('PR_ALL_INVOLVE_ME'),
        cache_dir: ENV['alfred_workflow_cache'],
        cache_ttl_sec_repo: ENV['CACHE_TTL_SEC_REPO'].to_i,
        cache_ttl_sec_org: ENV['CACHE_TTL_SEC_ORG'].to_i,
        cache_ttl_sec_pr: ENV['CACHE_TTL_SEC_PR'].to_i
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
      Commands::UserPulls.new(
        pull_requests: pull_requests,
        web_host: ENV['GITHUB_HOST']
      )
    end

    private
    def bool_env(env_var_name)
      ENV.fetch(env_var_name, 'false').downcase == 'true'
    end
  end
end
