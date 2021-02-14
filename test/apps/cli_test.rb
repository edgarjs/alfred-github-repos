# frozen_string_literal: true

require 'test_helper'
require 'commands/help'
require 'commands/search'
require 'commands/user_repos'
require 'commands/user_pulls'
load 'cli'

module Apps
  class CliTest < Minitest::Test
    def subject
      @subject ||= Apps::Cli.new(
        search: search,
        user_repos: user_repos,
        user_pulls: user_pulls,
        help: help
      )
    end

    def help
      @help ||= Commands::Help.new
    end

    def search
      @search ||= Commands::Search.new(
        repositories: stub('data_source.repositories')
      )
    end

    def user_repos
      @user_repos ||= Commands::UserRepos.new(
        repositories: stub('data_source.repositories')
      )
    end

    def user_pulls
      @user_pulls ||= Commands::UserPulls.new(
        pull_requests: stub('data_source.pull_requests'),
        web_host: 'www.example.com'
      )
    end

    def test_empty_arguments_calls_help_command
      help.expects(:call).once.with(%w[]).returns('help')
      assert_raises 'help' do
        subject.call(%w[])
      end
    end

    def test_help_argument_calls_help_command
      help.expects(:call).once.with(%w[]).returns('help')
      actual = subject.call(%w[help])
      assert_equal 'help', actual
    end

    def test_search_argument_calls_search_command
      search.expects(:call).once.with(%w[foo]).returns('results')
      actual = subject.call(%w[search foo])
      assert_equal 'results', actual
    end

    def test_user_repos_argument_calls_user_repos_command
      user_repos.expects(:call).once.with(%w[foo]).returns('results')
      actual = subject.call(%w[user-repos foo])
      assert_equal 'results', actual
    end

    def test_user_pulls_argument_calls_user_pulls_command
      user_pulls.expects(:call).once.with(%w[foo]).returns('results')
      actual = subject.call(%w[user-pulls foo])
      assert_equal 'results', actual
    end
  end
end
