# frozen_string_literal: true

require 'test_helper'
require 'data_source/repositories'
require 'entities/repository'

module DataSource
  class RepositoriesTest < Minitest::Test
    def subject
      @subject ||= Repositories.new(client: client)
    end

    def client
      @client ||= stub('data_source.client')
    end

    def results_stub
      JSON.parse(
        File.read('test/stubs/github/search_repos.json'),
        symbolize_names: true
      )[:items]
    end

    def test_search_with_no_query_returns_empty_array
      actual = subject.search({})
      assert_equal [], actual
    end

    def test_search_calls_client_with_parameters
      params = { query: 'hello-world' }
      client.expects(:search_repos).with(params).returns(results_stub)
      subject.search(params)
    end

    def test_search_returns_repository_entities
      client.stubs(:search_repos).returns(results_stub)
      result = subject.search(query: 'hello-world')
      assert_kind_of Entities::Repository, result[0]
    end

    def test_user_repos_calls_client_without_parameters
      client.expects(:user_repos).returns(results_stub)
      subject.user_repos
    end

    def test_user_repos_returns_repository_entities
      client.stubs(:user_repos).returns(results_stub)
      result = subject.user_repos
      assert_kind_of Entities::Repository, result[0]
    end
  end
end
