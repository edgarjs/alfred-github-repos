# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'cgi'
require 'github/repo'
require 'github/authorization'
require 'local_storage'
require 'config_path'

module Github
  class Api
    LEGACY_HOST_FILE = '~/.github-repos/host'
    DEFAULT_HOST = 'https://api.github.com'
    HOST_FILE_NAME = 'host'
    CACHE_FILE_NAME = 'cache'
    CACHE_TIMESTAMP_FILE_NAME = 'cache-timestamp'

    # Remember to update Readme if changed.
    CACHE_LIFETIME = 86_400 # 24 hours

    # 100 is maximum items per page
    LIST_USER_REPOS_PATH = '/user/repos?per_page=100'

    def search_all_repos(query)
      path = "/search/repositories?q=#{escape(query)}"

      repos = get(path)[:body][:items]

      repos.map do |i|
        Github::Repo.from_api_response(i).to_alfred_hash
      end
    end

    def search_repos(query)
      query_downcase = query.downcase

      repos = read_cached_repos
      repos = reset_cache if repos.empty?

      repos_filtered = repos.filter do |i|
        title_downcase = i.name.downcase
        title_downcase.include?(query_downcase)
      end

      repos_filtered.map(&:to_alfred_hash)
    end

    def reset_cache
      next_page = 1
      repos = []

      until next_page.nil?
        response = get(LIST_USER_REPOS_PATH + "&page=#{next_page}")
        repos_from_response = response[:body].map do |i|
          Github::Repo.from_api_response(i)
        end
        repos.push(*repos_from_response)
        next_page = response[:next_page]
      end

      save_repos_to_disk(repos)
      repos
    end

    class << self
      def host_storage
        host_path = ConfigPath.new(HOST_FILE_NAME, LEGACY_HOST_FILE).get
        LocalStorage.new(host_path)
      end

      def configure_host(host)
        host_storage.put("#{host}/api/v3")
      end
    end

    private

    def host
      @host ||= (Api.host_storage.get || DEFAULT_HOST)
    end

    def escape(str)
      CGI.escape(str)
    end

    def get(path)
      req = Net::HTTP::Get.new(path)
      uri = URI("#{host}#{req.path}")

      authorize(req)

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        yield(http) if block_given?
        http.request(req)
      end

      {
        body: parse_body(res.body),
        next_page: get_next_page(res[:link])
      }
    end

    def auth
      @auth ||= Authorization.authorize!
    end

    def authorize(request)
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/vnd.github.v3+json'
      request['User-Agent'] = 'Github Repos'
      request.basic_auth(auth.username, auth.token)
      request
    end

    def parse_body(body)
      return body if body.nil? || body.empty?

      JSON.parse(body, symbolize_names: true)
    end

    def get_next_page(header)
      return unless header

      # GitHub pagination returns a "Link" header in the following format:
      # <https://api.github.com/user/repos?per_page=100&page=2>; rel="last",
      # <https://api.github.com/user/repos?per_page=100&page=2>; rel="next"
      # We are currently interested only in the "next" link.

      # Proceed with part in the < > only if "next" word is in the string
      # In lt/gt "brackets", match digit after "page" query string, ensuring
      # it's not a "per_page" parameter by asking for [&?] to precede "page".
      regex = /<.+[&?]page=(\d+).*>.+next/
      header.split(',').map { |i| i[regex, 1] }.find(&:itself)
    end

    def save_repos_to_disk(repos)
      cache_path = ConfigPath.new(CACHE_FILE_NAME).get
      cache = LocalStorage.new(cache_path, serialize: false)
      content = repos.map(&:to_storage_string).join("\n")
      cache.put(content)
      save_cache_timestamp_to_disk
    end

    def read_cache_timestamp
      path = ConfigPath.new(CACHE_TIMESTAMP_FILE_NAME).get
      r = LocalStorage.new(path, serialize: false).get

      r.nil? ? 0 : r.to_i
    end

    def save_cache_timestamp_to_disk
      path = ConfigPath.new(CACHE_TIMESTAMP_FILE_NAME).get
      LocalStorage.new(path, serialize: false).put(Time.now.to_i)
    end

    def read_cached_repos
      cache_path = ConfigPath.new(CACHE_FILE_NAME).get
      cache_string = LocalStorage.new(cache_path, serialize: false).get
      cache_expired = (read_cache_timestamp + CACHE_LIFETIME) < Time.now.to_i

      if !cache_string.nil? && !cache_expired
        cache_string.split("\n").map do |i|
          Github::Repo.from_storage_string(i)
        end
      else
        []
      end
    end
  end
end
