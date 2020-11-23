# frozen_string_literal: true

require 'net/http'
require 'json'
require 'fileutils'

module DataSource
  module Client
    class Github
      CACHE_TTL_SECS = 3600 * 12

      def initialize(config)
        @host = config[:host]
        @access_token = config[:access_token]
        @cache_dir = config[:cache_dir]
      end

      def search_repos(params)
        modifiers = ['in:name']
        modifiers += org_modifiers('user:@me') if params[:mine]
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
        with_cache('user_repos') do
          request('/user/repos', params)
        end
      end

      def user_pulls
        modifiers = org_modifiers('is:pr', 'user:@me', 'state:open', 'involves:@me')
        params = search_params('', modifiers).merge(
          per_page: 100
        )
        response = with_cache('user_pulls') do
          request('/search/issues', params)
        end
        response[:items]
      end

      private

      def search_params(query, modifiers)
        { q: "#{query} #{modifiers.join(' ')}" }
      end

      def org_modifiers(*initial)
        orgs = with_cache('user_orgs') { request('/user/orgs') }
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

        res = block.call
        write_cache(filename, res.body) if res.is_a?(Net::HTTPSuccess)
        handle_response(res)
      end

      def read_cache(filename)
        return unless @cache_dir

        path = File.join(@cache_dir, filename)
        return unless File.exist?(path)

        file = File.stat(path)
        return if (Time.now - file.mtime) >= CACHE_TTL_SECS

        deserialize_body(File.read(path))
      rescue JSON::ParserError
        nil
      end

      def write_cache(filename, value)
        return value unless @cache_dir

        FileUtils.mkdir_p(@cache_dir) unless File.directory?(@cache_dir)
        path = File.join(@cache_dir, filename)
        File.open(path, 'w') { |f| f.write(value) }
        value
      end

      def build_request(uri)
        request = Net::HTTP::Get.new(uri)
        request['Accept'] = request['Content-Type'] = 'application/vnd.github.v3+json'
        request.basic_auth('', @access_token)
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
