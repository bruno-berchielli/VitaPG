require "test_helper"

module Backups
  class CommandRunnerTest < ActiveSupport::TestCase
    test "streams stderr lines as the child produces them" do
      seen = []
      result = CommandRunner.run(
        [ "sh", "-c", "echo one >&2; echo two >&2" ],
        on_stderr_line: ->(line) { seen << line }
      )

      assert result.success?
      assert_equal %w[one two], seen
      assert_equal "one\ntwo\n", result.stderr
    end

    test "a raising observer does not break the command" do
      result = CommandRunner.run(
        [ "sh", "-c", "echo boom >&2" ],
        on_stderr_line: ->(_line) { raise "observer bug" }
      )

      assert result.success?
      assert_equal "boom\n", result.stderr
    end
  end
end
