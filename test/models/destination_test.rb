require "test_helper"

class DestinationTest < ActiveSupport::TestCase
  setup do
    @destination = destinations(:minio)
  end

  test "local destinations require a safe absolute base path and skip S3 fields" do
    @destination.assign_attributes(provider: "local", bucket: nil, access_key_id: nil,
                                   secret_access_key: nil, base_path: nil)
    assert_not @destination.valid?
    assert @destination.errors[:base_path].any?

    @destination.base_path = "relative/path"
    # normalizes expands to an absolute path, so a relative input becomes valid
    assert @destination.valid?
    assert @destination.base_path.start_with?("/")

    @destination.base_path = "/"
    assert_not @destination.valid?

    @destination.base_path = "/var/backups/vitapg"
    assert @destination.valid?
  end

  test "adapter and location follow the provider" do
    assert_instance_of Storage::S3Adapter, @destination.adapter
    assert_equal "backups", @destination.location

    @destination.assign_attributes(provider: "local", base_path: "/var/backups/vitapg")
    assert_instance_of Storage::LocalAdapter, @destination.adapter
    assert_equal "/var/backups/vitapg", @destination.location
  end
end
