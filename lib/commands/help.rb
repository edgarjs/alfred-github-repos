# frozen_string_literal: true

require 'commands/search'
require 'version'

module Commands
  class Help

    HEAD = <<~HEAD
      GitHub Repos workflow for Alfred - CLI
      Version: #{App::VERSION}
    HEAD

    TAIL = <<~TAIL
      Available commands:
        search, user-repos, user-pulls, help

      Run `cli help <COMMAND>` to see the options of a command.
    TAIL

    MESSAGES = {
      default: <<~DEFAULT,
        Usage: cli <COMMAND> [options]
      DEFAULT

      search: Search.help
    }.freeze

    def call(args)
      command = args.first&.to_sym
      body = MESSAGES.key?(command) ? MESSAGES[command] : MESSAGES[:default]

      "#{HEAD}\n#{body}\n#{TAIL}\n"
    end
  end
end
