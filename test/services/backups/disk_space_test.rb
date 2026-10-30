require "test_helper"

module Backups
  class DiskSpaceTest < ActiveSupport::TestCase
    test "reads free bytes for an existing path" do
      assert_operator DiskSpace.free_bytes(Dir.tmpdir), :>, 0
    end

    test "returns nil when the path cannot be inspected" do
      assert_nil DiskSpace.free_bytes("/nonexistent/vitapg/path")
    end
  end
end
