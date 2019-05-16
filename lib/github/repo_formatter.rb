# frozen_string_literal: true

require 'json'

module Github
  class RepoFormatter
    def initialize(repos)
      @repos = repos
    end

    def to_json(*_args)
      items = @repos.map do |repo|
        format_repo(repo)
      end

      JSON.generate(items: items)
    end

    private

    def format_repo(repo)
      {
        title: repo[:full_name],
        subtitle: repo[:html_url],
        arg: repo[:html_url],
        text: {
          copy: repo[:html_url],
          largetype: repo[:html_url]
        }
      }
    end
  end
end
