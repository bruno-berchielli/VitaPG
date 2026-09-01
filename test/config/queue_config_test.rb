require "test_helper"

class QueueConfigTest < ActiveSupport::TestCase
  # Backup routines are dynamic recurring tasks; without this flag Solid
  # Queue's scheduler silently skips them and no scheduled backup ever runs.
  test "every environment keeps dynamic recurring tasks enabled" do
    config = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/queue.yml"))
    config = config.deep_symbolize_keys

    %i[development test production].each do |env|
      assert_equal true, config.dig(env, :scheduler, :dynamic_tasks_enabled),
        "expected #{env} scheduler to enable dynamic recurring tasks"
    end
  end
end
