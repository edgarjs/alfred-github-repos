# frozen_string_literal: true

module Entities
  PullRequest = Struct.new(
    :id,
    :number,
    :title,
    :html_url,
    keyword_init: true
  ) do
    def as_alfred_item
      {
        title: title,
        subtitle: html_url,
        arg: html_url,
        text: {
          copy: html_url,
          largetype: title
        }
      }
    end
  end
end
