# frozen_string_literal: true

require 'test_helper'
require 'commands/search'
require 'entities/repository'

module Commands
  class SearchTest < Minitest::Test
    def subject
      @subject ||= Search.new(repositories: repositories)
    end

    def repositories
      @repositories ||= stub('data_source.repositories')
    end

    def repository_entity
      @repository_entity ||= Entities::Repository.new
    end

    def test_returns_empty_array_with_empty_query
      repositories.expects(:search).never
      actual = subject.call([])
      assert_equal '{"items":[]}', actual
    end

    def test_search_query_in_repositories
      repositories.expects(:search).with(query: 'octocat').returns([])
      subject.call(%w[octocat])
    end

    def test_search_type_repo_returns_alfred_items_json
      repositories.expects(:search).returns([repository_entity])
      actual = subject.call(%w[octocat])
      expected = JSON.generate(items: [repository_entity.as_alfred_item])
      assert_equal expected, actual
    end
  end
end
