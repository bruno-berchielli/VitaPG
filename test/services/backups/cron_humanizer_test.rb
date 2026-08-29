require "test_helper"

module Backups
  class CronHumanizerTest < ActiveSupport::TestCase
    test "humanizes the common shapes in English" do
      I18n.with_locale(:en) do
        assert_equal "Every day at 03:00", CronHumanizer.humanize("0 3 * * *")
        assert_equal "Weekdays at 03:00", CronHumanizer.humanize("0 3 * * 1-5")
        assert_equal "Every Sunday at 03:00", CronHumanizer.humanize("0 3 * * 0")
        assert_equal "Every month on day 1 at 03:00", CronHumanizer.humanize("0 3 1 * *")
        assert_equal "Every hour", CronHumanizer.humanize("0 * * * *")
        assert_equal "Every hour at minute 30", CronHumanizer.humanize("30 * * * *")
        assert_equal "Every 15 minutes", CronHumanizer.humanize("*/15 * * * *")
        assert_equal "Every 6 hours", CronHumanizer.humanize("0 */6 * * *")
      end
    end

    test "humanizes in pt-BR" do
      I18n.with_locale(:"pt-BR") do
        assert_equal "Todos os dias às 03:00", CronHumanizer.humanize("0 3 * * *")
        assert_equal "Toda segunda-feira às 02:30", CronHumanizer.humanize("30 2 * * 1")
      end
    end

    test "returns nil for shapes it does not recognize" do
      assert_nil CronHumanizer.humanize("*/5 2 * * *")
      assert_nil CronHumanizer.humanize("0 3 1 6 *")
      assert_nil CronHumanizer.humanize("0 3 * * 1,3,5")
      assert_nil CronHumanizer.humanize("not a cron")
    end

    test "every preset is humanizable" do
      I18n.with_locale(:en) do
        CronHumanizer::PRESETS.each do |preset|
          assert CronHumanizer.humanize(preset).present?, "expected preset #{preset} to humanize"
        end
      end
    end
  end
end
