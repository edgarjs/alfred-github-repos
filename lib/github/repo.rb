# frozen_string_literal: true

require 'json'

module Github
  class Repo
    attr_reader :name, :link

    def initialize(name, link)
      @name = name
      @link = link
    end

    def to_storage_string
      "#{@name},#{@link}"
    end

    def to_alfred_hash
      {
        title: @name,
        subtitle: @link,
        arg: @link,
        text: {
          copy: @link,
          largetype: @link
        }
      }
    end

    class << self
      def from_storage_string(storage_string)
        name, link = storage_string.split(',')
        new(name, link)
      end

      def from_api_response(api_response)
        new(api_response[:full_name], api_response[:html_url])
      end
    end
  end
end
