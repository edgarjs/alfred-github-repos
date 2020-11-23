# frozen_string_literal: true

require 'test_helper'
require 'data_source/pull_requests'
require 'entities/pull_request'

module DataSource
  class PullRequestsTest < Minitest::Test
    def subject
      @subject ||= PullRequests.new(client: client)
    end

    def client
      @client ||= stub('data_source.client')
    end

    def results_stub
      JSON.parse(
        File.read('test/stubs/github/search_pulls.json'),
        symbolize_names: true
      )[:items]
    end

    def test_user_pulls_calls_client
      client.expects(:user_pulls).returns([])
      subject.user_pulls
    end

    def test_user_pulls_returns_pull_request_entities
      client.stubs(:user_pulls).returns(results_stub)
      result = subject.user_pulls
      assert_kind_of Entities::PullRequest, result[0]
    end
  end
end
