# frozen_string_literal: true

require 'ostruct'
require 'test_helper'
require 'commands/user_pulls'
require 'entities/pull_request'

module Commands
  class UserPullsTest < Minitest::Test
    def subject
      @subject ||= UserPulls.new(
        pull_requests: pull_requests,
        web_host: 'www.example.com'
      )
    end

    def pull_requests
      @pull_requests ||= stub('data_source.pull_requests')
    end

    def pull_entity
      @pull_entity ||= Entities::PullRequest.new
    end

    def serialize_items(items)
      JSON.generate(items: items.map(&:as_alfred_item))
    end

    def test_calls_pull_requests_data_source
      pull_requests.expects(:user_pulls).returns([])
      subject.call([])
    end

    def test_fuzzy_filters_pulls_title
      pull1 = Entities::PullRequest.new(title: 'foo bar-baz')
      pull2 = Entities::PullRequest.new(title: 'hello-world')
      pull_requests.expects(:user_pulls).returns([pull1, pull2])
      actual = subject.call(%w[fobz])
      expected = serialize_items([pull1])
      assert_equal expected, actual
    end

    def test_fuzzy_filters_pulls_html_url
      pull1 = Entities::PullRequest.new(html_url: 'foo bar-baz')
      pull2 = Entities::PullRequest.new(html_url: 'hello-world')
      pull_requests.expects(:user_pulls).returns([pull1, pull2])
      actual = subject.call(%w[fobz])
      expected = serialize_items([pull1])
      assert_equal expected, actual
    end

    def test_inserts_open_pulls_page_when_no_args
      pull_requests.expects(:user_pulls).returns([pull_entity])
      actual = subject.call([])
      url = 'https://www.example.com/pulls'
      open_page_item = OpenStruct.new(
        as_alfred_item: {
          title: 'Open your Pull Requests page...',
          subtitle: url,
          arg: url,
          text: {
            copy: url
          }
        }
      )
      expected = serialize_items([open_page_item, pull_entity])
      assert_equal expected, actual
    end
  end
end
