# frozen_string_literal: true

require 'net/http'
require 'json'
require 'fileutils'

module DataSource
  module Client
    class GitHub

      def initialize(config)
        @config = {
          host: 'api.github.com',
          access_token: nil,
          me_account: '@me',
          pr_all_involve_me: false,
          cache_dir: nil,
          cache_ttl_sec_repo: 24 * 60 * 60,
          cache_ttl_sec_org: 24 * 60 * 60,
          cache_ttl_sec_pr: 5 * 60,
        }.merge(config)

        @cache_name_hash = {
          user_repos: 'user_repos',
          user_orgs: 'user_orgs',
          user_pulls: 'user_pulls'
        }

        @cache_ttl_hash = {
          user_repos: @config[:cache_ttl_sec_repo],
          user_orgs: @config[:cache_ttl_sec_org],
          user_pulls: @config[:cache_ttl_sec_pr]
        }
      end

      def search_repos(params)
        modifiers = ['in:name']
        modifiers += org_modifiers("user:#{@config[:me_account]}") if params[:mine]
        params = search_params(params[:query], modifiers)
        response = request('/search/repositories', params)
        handle_response(response)[:items]
      end

      def user_repos
        params = {
          sort: 'pushed',
          direction: 'desc',
          per_page: 100
        }
        responses = with_cache(:user_repos) do
          merge_multipage_results('/user/repos', params, 100)
        end
        responses.flatten(1)
      end

      def user_pulls
        params = search_params('', pull_modifiers).merge(
          per_page: 100
        )
        responses = with_cache(:user_pulls) do
          merge_multipage_results('/search/issues', params, 100)
        end

        responses.flat_map {|r| r[:items]}
      end

      private

      def merge_multipage_results(path, params, per_page)
        params[:per_page] = per_page
        params[:page] = 1
        res = request(path, params)
        raise res[:message] unless res.is_a?(Net::HTTPSuccess)

        result = [deserialize_body(res.body)]

        page_count = results_last_page(res)

        (2..page_count).step(1) do |n|
          params[:page] = n
          params[:per_page] = per_page
          part_res = request(path, params)
          if not part_res.is_a?(Net::HTTPSuccess)
            result = nil
            break
          else
            result << deserialize_body(part_res.body)
          end
        end
        result
      end

      def results_last_page(res)
        page_count = 1
        if res.key?("Link")
          res["Link"].split(",").find do |link|
            page_num, rel = link.match(/&page=(\d+)>; .*?"(\w+)"/i).captures
            page_count = page_num.to_i if rel == "last"
          end
        end
        page_count
      end


      def search_params(query, modifiers)
        { q: "#{query} #{modifiers.join(' ')}" }
      end

      def pull_modifiers
        if @config[:pr_all_involve_me]
          ['is:pr', 'state:open', "involves:#{@config[:me_account]}"]
        else
          org_modifiers('is:pr', "user:#{@config[:me_account]}", 'state:open', "involves:#{@config[:me_account]}")
        end
      end

      def org_modifiers(*initial)
        orgs = with_cache(:user_orgs) do
          res = request('/user/orgs')
          res.is_a?(Net::HTTPSuccess) ? deserialize_body(res.body) : []
        end
        orgs.inject(initial) do |memo, org|
          memo << "org:#{org[:login]}"
        end
      end

      def request(path, params = {})
        uri = URI("https://#{@config[:host]}#{path}")
        params[:per_page] ||= 10
        uri.query = URI.encode_www_form(params)
        request = build_request(uri)
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
      end

      def with_cache(filename, &block)
        cache = read_cache(filename)
        return cache if cache
        ret = block.call
        write_cache(filename, ret)
        ret
      end

      def read_cache(filename)
        return unless @config[:cache_dir]

        path = File.join(@config[:cache_dir], @cache_name_hash[filename])
        return unless File.exist?(path)

        file = File.stat(path)
        return if (Time.now - file.mtime) >= @cache_ttl_hash[filename]

        deserialize_body(File.read(path))
      rescue JSON::ParserError
        nil
      end

      def write_cache(filename, value)
        return value unless @config[:cache_dir]

        FileUtils.mkdir_p(@config[:cache_dir]) unless File.directory?(@config[:cache_dir])
        path = File.join(@config[:cache_dir], @cache_name_hash[filename])
        File.open(path, 'w') { |f| f.write(JSON.dump(value)) }
        value
      end

      def build_request(uri)
        request = Net::HTTP::Get.new(uri)
        request['Accept'] = request['Content-Type'] = 'application/vnd.github.v3+json'
        request.basic_auth('', @config[:access_token])
        request
      end

      def handle_response(response)
        res = deserialize_body(response.body)
        raise res[:message] unless response.is_a?(Net::HTTPSuccess)

        res
      end

      def deserialize_body(body)
        JSON.parse(body, symbolize_names: true)
      end
    end
  end
end
