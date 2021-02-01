# frozen_string_literal: true

require 'net/http'
require 'json'
require 'fileutils'

module DataSource
  module Client
    class Github

      def initialize(config)
        @host = config[:host]
        @access_token = config[:access_token]
        @cache_dir = config[:cache_dir]
        @me_account = config[:me_account]
        @pr_all_involve_me = config[:pr_all_involve_me]

        @cache_name_hash = {
            user_repos: 'user_repos',
            user_orgs: 'user_orgs',
            user_pulls: 'user_pulls'
        }

        @cache_ttl_hash = {
            user_repos: config[:cache_ttl_sec_repo],
            user_orgs: config[:cache_ttl_sec_org],
            user_pulls: config[:cache_ttl_sec_pr]
        }
      end

      def search_repos(params)
        modifiers = ['in:name']
        modifiers += org_modifiers("user:#@me_account") if params[:mine]
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
        with_cache(:user_repos) do

          page_count = get_total_page_for_request('/user/repos', params)
          if page_count != nil
            all_user_repos = Array.new
            write = true
            (1..page_count).step(1) do |n|
              params[:page] = n
              part_res = request('/user/repos', params)
              if not part_res.is_a?(Net::HTTPSuccess)
                write = false
                break
              else
                all_user_repos = all_user_repos+ deserialize_body(part_res.body)
              end
            end
            {write: write, cache_content: all_user_repos}
          else
            res = request('/user/repos', params)
            if not res.is_a?(Net::HTTPSuccess)
              { write: false, cache_content: nil }
            else
              { write: true, cache_content: deserialize_body(res.body) }
            end
          end

        end

      end

      def user_pulls
        if @pr_all_involve_me.nil?
          modifiers = org_modifiers('is:pr', "user:#@me_account", 'state:open', "involves:#@me_account")
        else
          modifiers = ['is:pr', 'state:open', "involves:#@me_account"]
        end
        params = search_params('', modifiers).merge(
          per_page: 100
        )
        response = with_cache(:user_pulls) do
          page_count = get_total_page_for_request('/search/issues', params)
          if page_count != nil
            all_user_pulls = Array.new
            write = true
            (1..page_count).step(1) do |n|
              params[:page] = n
              part_res = request('/search/issues', params)
              if not part_res.is_a?(Net::HTTPSuccess)
                write = false
                break
              else
                all_user_pulls = all_user_pulls+ deserialize_body(part_res.body)
              end
            end
            {write: write, cache_content: all_user_pulls}
          else
            res = request('/search/issues', params)
            if not res.is_a?(Net::HTTPSuccess)
              { write: false, cache_content: nil }
            else
              { write: true, cache_content: deserialize_body(res.body) }
            end
          end
        end
        response[:items]
      end

      private

      def search_params(query, modifiers)
        { q: "#{query} #{modifiers.join(' ')}" }
      end

      def org_modifiers(*initial)
        orgs = with_cache(:user_orgs) do
          res = request('/user/orgs')
          if not res.is_a?(Net::HTTPSuccess)
            { write: false, cache_content: nil }
          else
            { write: true, cache_content: deserialize_body(res.body) }
          end
        end
        orgs.inject(initial) do |memo, org|
          memo << "org:#{org[:login]}"
        end
      end

      def request(path, params = {})
        uri = URI("https://#{@host}#{path}")
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
        write_cache(filename, JSON.dump(ret[:cache_content])) if ret[:write]
        ret[:cache_content]
      end

      def read_cache(filename)
        return unless @cache_dir

        path = File.join(@cache_dir, @cache_name_hash[filename])
        return unless File.exist?(path)

        file = File.stat(path)
        return if (Time.now - file.mtime) >= @cache_ttl_hash[filename]

        deserialize_body(File.read(path))
      rescue JSON::ParserError
        nil
      end

      def write_cache(filename, value)
        return value unless @cache_dir

        FileUtils.mkdir_p(@cache_dir) unless File.directory?(@cache_dir)
        path = File.join(@cache_dir, @cache_name_hash[filename])
        File.open(path, 'w') { |f| f.write(value) }
        value
      end

      def build_request(uri)
        request = Net::HTTP::Get.new(uri)
        request['Accept'] = request['Content-Type'] = 'application/vnd.github.v3+json'
        request.basic_auth('', @access_token)
        request
      end

      def get_total_page_for_request(path, params = {})
        res = request(path, params)
        raise res[:message] unless res.is_a?(Net::HTTPSuccess)

        begin
          res.header["Link"].split(",").map do |result|
            page_num, rel = result.match(/&page=(\d+)>; .*?"(\w+)"/i).captures
            return page_num.to_i if rel == "last"
          end
        rescue StandardError => e
          nil
        end
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
