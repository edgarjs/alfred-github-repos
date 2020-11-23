# frozen_string_literal: true

require 'test_helper'
require 'entities/pull_request'

module Entities
  class PullRequestTest < Minitest::Test
    def subject
      PullRequest
    end

    def test_initializes_with_id
      actual = subject.new(id: 1)
      assert_equal 1, actual.id
    end

    def test_initializes_with_number
      actual = subject.new(number: 1)
      assert_equal 1, actual.number
    end

    def test_initializes_with_title
      actual = subject.new(title: 'hello world')
      assert_equal 'hello world', actual.title
    end

    def test_initializes_with_html_url
      actual = subject.new(html_url: 'http://example.com')
      assert_equal 'http://example.com', actual.html_url
    end

    def test_as_alfred_item_returns_hash
      instance = subject.new(
        id: 1,
        number: 1,
        title: 'title',
        html_url: 'html url'
      )
      expected = {
        title: 'title',
        subtitle: 'html url',
        arg: 'html url',
        text: {
          copy: 'html url',
          largetype: 'title'
        }
      }
      assert_equal expected, instance.as_alfred_item
    end
  end
end
