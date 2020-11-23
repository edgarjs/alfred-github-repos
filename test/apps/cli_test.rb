# frozen_string_literal: true

require 'test_helper'
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
      @help ||= stub('commands.help')
    end

    def search
      @search ||= stub('commands.search')
    end

    def user_repos
      @user_repos ||= stub('commands.user_repos')
    end

    def user_pulls
      @user_pulls ||= stub('commands.user_pulls')
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
