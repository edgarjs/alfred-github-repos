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

    # 100 is maximum items per page
    LIST_USER_REPOS_PATH = '/user/repos?per_page=100'

    def search_all_repos(query)
      path = "/search/repositories?q=#{escape(query)}"

      repos = get(path)[:body][:items]

      repos.map do |i|
        Repo.from_api_response(i).to_alfred_hash
      end
    end

    def search_repos(query)
      query_downcase = query.downcase

      repos = read_cached_repos
      repos = reset_cache if repos.empty?

      repos_filtered = repos.select do |i|
        title_downcase = i.name.downcase
        title_downcase.include?(query_downcase)
      end

      if repos_filtered.empty?
        return [{ title: 'Repository not found. Reset cache?', arg: 'reset_cache' }]
      end

      repos_filtered.map(&:to_alfred_hash)
    end

    def reset_cache
      next_page = 1
      repos = []

      until next_page.nil?
        response = get(LIST_USER_REPOS_PATH + "&page=#{next_page}")
        repos_from_response = response[:body].map do |i|
          Repo.from_api_response(i)
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

    def cache_storage
      @cache_path ||= ConfigPath.new(CACHE_FILE_NAME)
      @cache_storage ||= LocalStorage.new(@cache_path.get, serialize: false)
    end

    def save_repos_to_disk(repos)
      content = repos.map(&:to_storage_string).join("\n")
      cache_storage.put(content)
    end

    # If you're looking for a way to check how old cache is -
    # look at code prior to commit 28e5ddd034552ec2b2df68ad5657adcdc093418e
    def read_cached_repos
      cache_string = cache_storage.get
      return [] if cache_string.nil?

      cache_string.split("\n").map { |i| Repo.from_storage_string(i) }
    end
  end
end
