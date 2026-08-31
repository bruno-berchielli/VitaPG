require "test_helper"

module Storage
  class LocalAdapterTest < ActiveSupport::TestCase
    setup do
      @base = Dir.mktmpdir("vitapg-local-dest-")
      @destination = destinations(:minio).tap do |d|
        d.assign_attributes(provider: "local", base_path: @base)
      end
      @adapter = LocalAdapter.new(@destination)
      @source = File.join(@base, "source.bin")
      File.binwrite(@source, "0123456789" * 1000)
    end

    teardown do
      FileUtils.remove_entry(@base)
    end

    test "upload stores the file under the base path and reports progress" do
      seen = []
      @adapter.upload!(@source, "acme/routine/backup-1.dump", on_progress: ->(b) { seen << b })

      stored = File.join(@base, "acme/routine/backup-1.dump")
      assert File.exist?(stored)
      assert_equal File.size(@source), File.size(stored)
      assert_equal File.size(@source), seen.last
      assert_empty Dir.glob(File.join(@base, "**", "*.partial"))
    end

    test "head_size and delete only see files under the base path" do
      @adapter.upload!(@source, "a/b.dump")

      assert_equal File.size(@source), @adapter.head_size("a/b.dump")
      @adapter.delete!("a/b.dump")
      assert_nil @adapter.head_size("a/b.dump")
    end

    test "keys escaping the base path are refused" do
      assert_raises(Backups::Error) { @adapter.head_size("../outside.dump") }
      assert_raises(Backups::Error) { @adapter.delete!("/etc/passwd") }
      assert_raises(Backups::Error) { @adapter.upload!(@source, "a/../../escape.dump") }
    end

    test "verify_access! demands an existing writable directory" do
      assert @adapter.verify_access!

      @destination.base_path = File.join(@base, "missing")
      error = assert_raises(Backups::Error) { LocalAdapter.new(@destination).verify_access! }
      assert_match(/does not exist/, error.message)
    end

    test "download_url is nil and file_path resolves for streaming" do
      @adapter.upload!(@source, "a/b.dump")

      assert_nil @adapter.download_url("a/b.dump")
      assert_equal File.join(@base, "a/b.dump"), @adapter.file_path("a/b.dump")
    end
  end
end
