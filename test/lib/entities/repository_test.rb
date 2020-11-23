# frozen_string_literal: true

require 'test_helper'
require 'entities/repository'

module Entities
  class RepositoryTest < Minitest::Test
    def subject
      Repository
    end

    def test_initializes_with_id
      actual = subject.new(id: 1)
      assert_equal 1, actual.id
    end

    def test_initializes_with_name
      actual = subject.new(name: 'name')
      assert_equal 'name', actual.name
    end

    def test_initializes_with_full_name
      actual = subject.new(full_name: 'full name')
      assert_equal 'full name', actual.full_name
    end

    def test_initializes_with_html_url
      actual = subject.new(html_url: 'http://example.com')
      assert_equal 'http://example.com', actual.html_url
    end

    def test_initializes_with_ssh_url
      actual = subject.new(ssh_url: 'git@example.com:foo/bar.git')
      assert_equal 'git@example.com:foo/bar.git', actual.ssh_url
    end

    def test_as_alfred_item_returns_hash
      instance = subject.new(
        id: 1,
        name: 'name',
        full_name: 'full name',
        html_url: 'html url',
        ssh_url: 'ssh url'
      )
      expected = {
        title: 'full name',
        subtitle: 'html url',
        arg: 'html url',
        text: {
          copy: 'ssh url',
          largetype: 'full name'
        }
      }
      assert_equal expected, instance.as_alfred_item
    end
  end
end
