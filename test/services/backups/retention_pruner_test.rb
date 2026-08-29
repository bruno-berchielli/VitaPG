require "test_helper"

module Backups
  class RetentionPrunerTest < ActiveSupport::TestCase
    class FakeAdapter
      attr_reader :deleted

      def initialize = @deleted = []
      def delete!(key) = @deleted << key
    end

    setup do
      @routine = backup_routines(:nightly)
      @adapter = FakeAdapter.new
    end

    def stub_adapter(fake)
      destination = @routine.destination
      destination.define_singleton_method(:adapter) { fake }
    end

    def create_run(key:, created_at:, status: :completed)
      @routine.runs.create!(status: status, file_key: key, created_at: created_at,
                            started_at: created_at, finished_at: created_at)
    end

    test "keeps the newest N completed runs" do
      old = create_run(key: "a/1.dump", created_at: 3.days.ago)
      create_run(key: "a/2.dump", created_at: 2.days.ago)
      create_run(key: "a/3.dump", created_at: 1.day.ago)

      stub_adapter(@adapter)
      assert_equal 1, RetentionPruner.call(@routine)

      assert_equal [ "a/1.dump" ], @adapter.deleted
      assert old.reload.pruned?
    end

    test "prunes runs older than max age" do
      @routine.update!(retention_keep_last: nil, retention_max_age_days: 7)
      old = create_run(key: "a/old.dump", created_at: 10.days.ago)
      recent = create_run(key: "a/new.dump", created_at: 1.day.ago)

      stub_adapter(@adapter)
      assert_equal 1, RetentionPruner.call(@routine)

      assert old.reload.pruned?
      assert recent.reload.completed?
    end

    test "ignores failed and in-progress runs" do
      create_run(key: nil, created_at: 10.days.ago, status: :failed)
      create_run(key: nil, created_at: 10.days.ago, status: :dumping)

      stub_adapter(@adapter)
      assert_equal 0, RetentionPruner.call(@routine)

      assert_empty @adapter.deleted
    end

    test "a failed deletion does not abort the batch" do
      failing = Object.new
      def failing.delete!(key)
        raise "boom" if key.include?("1")
      end

      create_run(key: "a/1.dump", created_at: 4.days.ago)
      create_run(key: "a/2.dump", created_at: 3.days.ago)
      @routine.update!(retention_keep_last: nil, retention_max_age_days: 1)

      stub_adapter(failing)
      assert_equal 1, RetentionPruner.call(@routine)
    end
  end
end
