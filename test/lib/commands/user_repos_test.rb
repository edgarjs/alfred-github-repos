# frozen_string_literal: true

require 'test_helper'
require 'commands/user_repos'
require 'entities/repository'

module Commands
  class UserReposTest < Minitest::Test
    def subject
      @subject ||= UserRepos.new(repositories: repositories)
    end

    def repositories
      @repositories ||= stub('data_source.repositories')
    end

    def repository_entity
      @repository_entity ||= Entities::Repository.new
    end

    def serialize_items(items)
      JSON.generate(items: items.map(&:as_alfred_item))
    end

    def test_calls_repositories_data_source
      repositories.expects(:user_repos).returns([])
      subject.call([])
    end

    def test_fuzzy_filters_repositories
      repo1 = Entities::Repository.new(full_name: 'foo/bar-baz')
      repo2 = Entities::Repository.new(full_name: 'octocat/hello-world')
      repositories.expects(:user_repos).returns([repo1, repo2])
      actual = subject.call(%w[fobz])
      expected = serialize_items([repo1])
      assert_equal expected, actual
    end

    def test_fuzzy_filters_ignores_case
      repo1 = Entities::Repository.new(full_name: 'Foo/BAR-baz')
      repo2 = Entities::Repository.new(full_name: 'octocat/foo-bar')
      repositories.expects(:user_repos).returns([repo1, repo2])
      actual = subject.call(%w[fob])
      expected = serialize_items([repo1, repo2])
      assert_equal expected, actual
    end

    def test_returns_alfred_items_json
      repositories.expects(:user_repos).returns([repository_entity])
      actual = subject.call([])
      expected = serialize_items([repository_entity])
      assert_equal expected, actual
    end
  end
end
