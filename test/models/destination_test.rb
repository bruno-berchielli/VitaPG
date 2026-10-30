require "test_helper"

class DestinationTest < ActiveSupport::TestCase
  setup do
    @destination = destinations(:minio)
  end

  test "endpoints drop the bucket from the host" do
    @destination.assign_attributes(bucket: "ez-backups", endpoint: "https://ez-backups.nyc3.digitaloceanspaces.com/")
    assert_equal "https://nyc3.digitaloceanspaces.com", @destination.service_endpoint

    @destination.valid?
    assert_equal "https://nyc3.digitaloceanspaces.com", @destination.endpoint
  end

  test "endpoints without the bucket are kept as they are" do
    @destination.assign_attributes(bucket: "ez-backups", endpoint: "http://localhost:59000")
    assert_equal "http://localhost:59000", @destination.service_endpoint

    @destination.endpoint = "https://ez-backups-archive.example.com"
    assert_equal "https://ez-backups-archive.example.com", @destination.service_endpoint
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
