# frozen_string_literal: true

require 'test_helper'
require 'commands/help'
require 'version'

module Commands
  class HelpTest < Minitest::Test
    HEAD = <<~HEAD
      GitHub Repos workflow for Alfred - CLI
      Version: #{App::VERSION}
    HEAD

    TAIL = <<~TAIL
      Available commands:
        search, user-repos, user-pulls, help

      Run `cli help <COMMAND>` to see the options of a command.
    TAIL

    def subject
      @subject ||= Help.new
    end

    def test_returns_global_help_message_by_default
      actual = subject.call(%w[])
      assert_equal <<~EXPECTED, actual
        #{HEAD}
        Usage: cli <COMMAND> [options]

        #{TAIL}
      EXPECTED
    end

    def test_returns_help_message_for_search_command
      actual = subject.call(%w[search])
      expected = <<~EXPECTED
        #{HEAD}
        Usage: cli search <query>
        #{TAIL}
      EXPECTED
      assert_equal expected, actual
    end
  end
end
