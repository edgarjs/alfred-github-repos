# frozen_string_literal: true

require 'test_helper'
require 'fileutils'
require 'data_source/client/github'

module DataSource
  module Client
    class GithubTest < Minitest::Test
      def setup
        super
        FileUtils.mkdir_p('tmp/cache')
        File.delete('tmp/cache/user_repos') if File.exist?('tmp/cache/user_repos')
        File.delete('tmp/cache/user_pulls') if File.exist?('tmp/cache/user_pulls')
        File.delete('tmp/cache/user_orgs') if File.exist?('tmp/cache/user_orgs')
      end

      def subject
        @subject ||= Github.new(host: 'example.com', access_token: 'test_token',
                                me_account: "@me", pr_all_involve_me: false)
      end

      def cache_ttl_sec_repo
        (24 * 60 * 60)
      end

      def cache_ttl_sec_org
        (24 * 60 * 60)
      end

      def cache_ttl_sec_pr
        (5 * 60)
      end

      def subject_with_cache
        @subject_with_cache ||= Github.new(
          host: 'example.com',
          access_token: 'test_token',
          cache_dir: 'tmp/cache',
          me_account: "@me",
          pr_all_involve_me: false,
          cache_ttl_sec_repo: (24 * 60 * 60),
          cache_ttl_sec_org: (24 * 60 * 60),
          cache_ttl_sec_pr: (5 * 60)
        )
      end

      def subject_with_pr_all_involve_me_true
        @subject_with_cache ||= Github.new(
          host: 'example.com',
          access_token: 'test_token',
          me_account: "@me",
          pr_all_involve_me: true,
        )
      end

      def search_repos_json
        File.read('test/stubs/github/search_repos.json')
      end

      def user_repos_json
        File.read('test/stubs/github/user_repos.json')
      end

      def search_pulls_json
        File.read('test/stubs/github/search_pulls.json')
      end

      def user_orgs_json
        File.read('test/stubs/github/user_orgs.json')
      end

      def response_error_json
        File.read('test/stubs/github/response_error.json')
      end

      def stub_search_repos_request(path = nil, opts = {})
        stub_request(:get, path || %r{/search/repositories}).to_return({
          status: 200,
          body: search_repos_json
        }.merge(opts))
      end

      def stub_user_repos_request(path = nil, opts = {})
        stub_request(:get, path || %r{/user/repos}).to_return({
          status: 200,
          body: user_repos_json
        }.merge(opts))
      end

      def stub_user_pulls_request(path = nil, opts = {})
        stub_request(:get, path || %r{/search/issues}).to_return({
          status: 200,
          body: search_pulls_json
        }.merge(opts))
      end

      def stub_user_orgs_request
        stub_request(:get, %r{/user/orgs}).to_return(
          status: 200,
          body: user_orgs_json
        )
      end

      def test_search_repos_uses_host
        expected = stub_search_repos_request(%r{^https://example.com/search/repositories})
        subject.search_repos(query: 'hello-world')
        assert_requested expected
      end

      def test_search_repos_uses_access_token
        expected = stub_search_repos_request.with(basic_auth: ['', 'test_token'])
        subject.search_repos(query: 'hello-world')
        assert_requested expected
      end

      def test_search_repos_uses_correct_content_type_headers
        content_type = 'application/vnd.github.v3+json'
        expected = stub_search_repos_request.with(
          headers: { 'Accept' => content_type, 'Content-Type' => content_type }
        )
        subject.search_repos(query: 'hello-world')
        assert_requested expected
      end

      def test_search_repos_uses_query_in_parameters
        expected = stub_search_repos_request(%r{/search/repositories\?.*q=hello-world})
        subject.search_repos(query: 'hello-world')
        assert_requested expected
      end

      def test_search_repos_asks_for_10_items_per_page
        expected = stub_search_repos_request(%r{/search/repositories\?.*per_page=10})
        subject.search_repos(query: 'hello-world')
        assert_requested expected
      end

      def test_search_repos_appends_in_name_modifier
        expected = stub_search_repos_request(%r{/search/repositories\?.*in:name})
        subject.search_repos(query: 'hello-world')
        assert_requested expected
      end

      def test_search_repos_returns_items
        stub_search_repos_request
        actual = subject.search_repos(query: 'hello-world')
        assert_equal 1, actual.count
      end

      def test_search_repos_with_error_response
        stub_search_repos_request(nil, status: 403, body: response_error_json)
        assert_raises(StandardError, 'API rate limit exceeded') do
          subject.search_repos(query: 'hello-world')
        end
      end

      def test_user_repos_uses_host
        expected = stub_user_repos_request(%r{^https://example.com/user/repos})
        subject.user_repos
        assert_requested expected
      end

      def test_user_repos_uses_access_token
        expected = stub_user_repos_request.with(basic_auth: ['', 'test_token'])
        subject.user_repos
        assert_requested expected
      end

      def test_user_repos_uses_correct_content_type_headers
        content_type = 'application/vnd.github.v3+json'
        expected = stub_user_repos_request.with(
          headers: { 'Accept' => content_type, 'Content-Type' => content_type }
        )
        subject.user_repos
        assert_requested expected
      end

      def test_user_repos_asks_for_100_items_per_page
        expected = stub_user_repos_request(%r{/user/repos\?.*per_page=100})
        subject.user_repos
        assert_requested expected
      end

      def test_user_repos_sort_by_pushed
        expected = stub_user_repos_request(%r{/user/repos\?.*sort=pushed})
        subject.user_repos
        assert_requested expected
      end

      def test_user_repos_sort_descending
        expected = stub_user_repos_request(%r{/user/repos\?.*direction=desc})
        subject.user_repos
        assert_requested expected
      end

      def test_user_repos_returns_items
        stub_user_repos_request
        actual = subject.user_repos
        assert_equal 1, actual.count
      end

      def test_user_repos_multipage
        expected = stub_user_repos_request(nil, {
            headers: {
                "Link" => '<https://example.com/?q=a&page=1>; rel="next", <https://example.com/?q=a&page=2>; rel="last"'
            }
        }).with(query: hash_including({"page"=>"1"}))
        second_expected = stub_user_repos_request.with(query: hash_including({"page"=>"2"}))

        actual = subject.user_repos
        assert_requested expected
        assert_requested second_expected

        assert_equal 2, actual.count
      end

      def test_user_repos_with_error_response
        stub_user_repos_request(nil, status: 403, body: response_error_json)
        assert_raises(StandardError, 'API rate limit exceeded') do
          subject.user_repos
        end
      end

      def test_user_repos_caches_response
        stub_user_repos_request
        subject_with_cache.user_repos
        assert File.exist?('tmp/cache/user_repos')
        File.delete('tmp/cache/user_repos')
      end

      def test_user_repos_returns_cache
        File.open('tmp/cache/user_repos', 'w') do |f|
          f.write "[" + user_repos_json + "]"
        end
        actual = subject_with_cache.user_repos
        assert_equal 1, actual.count
        File.delete('tmp/cache/user_repos')
      end

      def test_user_repos_skips_old_cache
        expired = Time.now - cache_ttl_sec_repo
        File.open('tmp/cache/user_repos', 'w') do |f|
          f.write user_repos_json
        end
        FileUtils.touch('tmp/cache/user_repos', mtime: expired)
        expected = stub_user_repos_request
        actual = subject_with_cache.user_repos
        assert_equal 1, actual.count
        assert_requested expected
        File.delete('tmp/cache/user_repos')
      end

      def test_user_repos_ignores_corrupted_cache
        File.open('tmp/cache/user_repos', 'w') do |f|
          f.write 'foobarbaz'
        end
        expected = stub_user_repos_request
        actual = subject_with_cache.user_repos
        assert_equal 1, actual.count
        assert_requested expected
        assert_equal JSON.dump([JSON.parse(user_repos_json)]), File.read('tmp/cache/user_repos')
        File.delete('tmp/cache/user_repos')
      end

      def test_user_pulls_uses_host
        stub_user_orgs_request
        expected = stub_user_pulls_request(%r{^https://example.com/search/issues})
        subject.user_pulls
        assert_requested expected
      end

      def test_user_pulls_uses_access_token
        stub_user_orgs_request
        expected = stub_user_pulls_request.with(basic_auth: ['', 'test_token'])
        subject.user_pulls
        assert_requested expected
      end

      def test_user_pulls_uses_correct_content_type_headers
        stub_user_orgs_request
        content_type = 'application/vnd.github.v3+json'
        expected = stub_user_pulls_request.with(
          headers: { 'Accept' => content_type, 'Content-Type' => content_type }
        )
        subject.user_pulls
        assert_requested expected
      end

      def test_user_pulls_asks_for_100_items_per_page
        stub_user_orgs_request
        expected = stub_user_pulls_request(%r{/search/issues\?.*per_page=100})
        subject.user_pulls
        assert_requested expected
      end

      def test_user_pulls_appends_is_pr_modifier
        stub_user_orgs_request
        expected = stub_user_pulls_request(%r{/search/issues\?.*is:pr})
        subject.user_pulls
        assert_requested expected
      end

      def test_user_pulls_appends_state_open_modifier
        stub_user_orgs_request
        expected = stub_user_pulls_request(%r{/search/issues\?.*state:open})
        subject.user_pulls
        assert_requested expected
      end

      def test_user_pulls_appends_user_me_modifier
        stub_user_orgs_request
        expected = stub_user_pulls_request(%r{/search/issues\?.*user:@me})
        subject.user_pulls
        assert_requested expected
      end

      def test_user_pulls_appends_involves_me_modifier
        stub_user_orgs_request
        expected = stub_user_pulls_request(%r{/search/issues\?.*involves:@me})
        subject.user_pulls
        assert_requested expected
      end

      def test_user_pulls_appends_org_modifier
        orgs = stub_user_orgs_request
        expected = stub_user_pulls_request(%r{/search/issues\?.*org:acme})
        subject.user_pulls
        assert_requested orgs
        assert_requested expected
      end

      def test_all_involves_user_pulls_appends_is_pr_modifier
        expected = stub_user_pulls_request(%r{/search/issues\?.*is:pr})
        subject_with_pr_all_involve_me_true.user_pulls
        assert_requested expected
      end

      def test_all_involves_user_pulls_appends_state_open_modifier
        expected = stub_user_pulls_request(%r{/search/issues\?.*state:open})
        subject_with_pr_all_involve_me_true.user_pulls
        assert_requested expected
      end

      def test_all_involves_user_pulls_not_appends_user_me_modifier
        stub_user_pulls_request
        not_expected = stub_user_pulls_request(%r{/search/issues\?.*user:@me})
        subject_with_pr_all_involve_me_true.user_pulls
        assert_not_requested not_expected
      end

      def test_all_involves_user_pulls_appends_involves_me_modifier
        expected = stub_user_pulls_request(%r{/search/issues\?.*involves:@me})
        subject_with_pr_all_involve_me_true.user_pulls
        assert_requested expected
      end

      def test_all_involves_user_pulls_no_org_request
        orgs = stub_user_orgs_request
        stub_user_pulls_request
        subject_with_pr_all_involve_me_true.user_pulls
        assert_not_requested orgs
      end

      def test_all_involves_user_pulls_not_appends_org_modifier
        stub_user_pulls_request
        not_expected = stub_user_pulls_request(%r{/search/issues\?.*org:acme})
        subject_with_pr_all_involve_me_true.user_pulls
        assert_not_requested not_expected
      end

      def test_user_pulls_returns_items
        stub_user_orgs_request
        stub_user_pulls_request
        actual = subject.user_pulls
        assert_equal 1, actual.count
      end

      def test_user_pulls_multipage
        stub_user_orgs_request

        expected = stub_user_pulls_request(nil, {
            headers: {
                "Link" => '<https://example.com/?q=a&page=1>; rel="next", <https://example.com/?q=a&page=2>; rel="last"'
            }
        }).with(query: hash_including({"page"=>"1"}))
        second_expected = stub_user_pulls_request.with(query: hash_including({"page"=>"2"}))

        actual = subject.user_pulls
        assert_requested expected
        assert_requested second_expected

        assert_equal 2, actual.count
      end

      def test_user_pulls_with_error_response
        stub_user_orgs_request
        stub_user_pulls_request(nil, status: 403, body: response_error_json)
        assert_raises(StandardError, 'API rate limit exceeded') do
          subject.user_pulls
        end
      end

      def test_user_pulls_caches_response
        stub_user_orgs_request
        stub_user_pulls_request
        subject_with_cache.user_pulls
        assert File.exist?('tmp/cache/user_orgs')
        assert File.exist?('tmp/cache/user_pulls')
        File.delete('tmp/cache/user_orgs')
        File.delete('tmp/cache/user_pulls')
      end

      def test_user_pulls_returns_cache
        File.open('tmp/cache/user_orgs', 'w') do |f|
          f.write user_orgs_json
        end
        File.open('tmp/cache/user_pulls', 'w') do |f|
          f.write "[" + search_pulls_json + "]"
        end
        actual = subject_with_cache.user_pulls
        assert_equal 1, actual.count
        File.delete('tmp/cache/user_orgs')
        File.delete('tmp/cache/user_pulls')
      end

      def test_user_pulls_skips_old_cache_for_pulls_request
        org_expired = Time.now - cache_ttl_sec_org
        pr_expired = Time.now - cache_ttl_sec_pr
        File.open('tmp/cache/user_orgs', 'w') do |f|
          f.write user_orgs_json
        end
        FileUtils.touch('tmp/cache/user_orgs', mtime: org_expired)
        File.open('tmp/cache/user_pulls', 'w') do |f|
          f.write search_pulls_json
        end
        FileUtils.touch('tmp/cache/user_orgs', mtime: org_expired)
        FileUtils.touch('tmp/cache/user_pulls', mtime: pr_expired)
        orgs_request = stub_user_orgs_request
        pulls_request = stub_user_pulls_request
        actual = subject_with_cache.user_pulls
        assert_equal 1, actual.count
        assert_requested orgs_request
        assert_requested pulls_request
        File.delete('tmp/cache/user_orgs')
        File.delete('tmp/cache/user_pulls')
      end

      def test_user_pulls_skips_old_cache_for_orgs_request
        org_expired = Time.now - cache_ttl_sec_org
        pr_expired = Time.now - cache_ttl_sec_pr
        File.open('tmp/cache/user_orgs', 'w') do |f|
          f.write user_orgs_json
        end
        FileUtils.touch('tmp/cache/user_orgs', mtime: org_expired)
        File.open('tmp/cache/user_pulls', 'w') do |f|
          f.write search_pulls_json
        end
        FileUtils.touch('tmp/cache/user_orgs', mtime: org_expired)
        FileUtils.touch('tmp/cache/user_pulls', mtime: pr_expired)
        orgs_request = stub_user_orgs_request
        pulls_request = stub_user_pulls_request
        actual = subject_with_cache.user_pulls
        assert_equal 1, actual.count
        assert_requested orgs_request
        assert_requested pulls_request
        File.delete('tmp/cache/user_orgs')
        File.delete('tmp/cache/user_pulls')
      end

      def test_user_pulls_ignores_corrupted_cache
        File.open('tmp/cache/user_orgs', 'w') do |f|
          f.write 'foobarbaz'
        end
        File.open('tmp/cache/user_pulls', 'w') do |f|
          f.write 'foobarbaz'
        end
        orgs_request = stub_user_orgs_request
        pulls_request = stub_user_pulls_request
        actual = subject_with_cache.user_pulls
        assert_equal 1, actual.count
        assert_requested orgs_request
        assert_requested pulls_request
        assert_equal JSON.dump([JSON.parse(search_pulls_json)]), File.read('tmp/cache/user_pulls')
        File.delete('tmp/cache/user_orgs')
        File.delete('tmp/cache/user_pulls')
      end
    end
  end
end
