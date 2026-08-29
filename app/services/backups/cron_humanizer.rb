# frozen_string_literal: true

module Backups
  # Translates the common cron shapes into a localized human sentence.
  # Anything it doesn't recognize returns nil and the UI falls back to the
  # raw expression.
  class CronHumanizer
    # Offered in the routine form's schedule picker, in this order.
    PRESETS = [
      "0 * * * *",
      "0 */6 * * *",
      "0 0 * * *",
      "0 3 * * *",
      "0 3 * * 1-5",
      "0 3 * * 0",
      "0 3 1 * *"
    ].freeze

    class << self
      # @return [String, nil]
      def humanize(cron)
        minute, hour, dom, month, dow = cron.to_s.strip.split(/\s+/)
        return nil unless dow && month == "*"

        if number?(minute) && number?(hour)
          time = format_time(hour, minute)

          if dom == "*" && dow == "*"
            I18n.t("cron.daily", time: time)
          elsif dom == "*" && dow == "1-5"
            I18n.t("cron.weekdays", time: time)
          elsif dom == "*" && single_weekday?(dow)
            I18n.t("cron.weekly", day: day_name(dow), time: time)
          elsif number?(dom) && dow == "*"
            I18n.t("cron.monthly", day: dom.to_i, time: time)
          end
        elsif dom == "*" && dow == "*"
          if minute.match?(%r{\A\*/\d+\z}) && hour == "*"
            I18n.t("cron.every_minutes", count: minute.delete_prefix("*/").to_i)
          elsif number?(minute) && hour == "*"
            minute.to_i.zero? ? I18n.t("cron.hourly") : I18n.t("cron.hourly_at", minute: minute.to_i)
          elsif number?(minute) && hour.match?(%r{\A\*/\d+\z})
            I18n.t("cron.every_hours", count: hour.delete_prefix("*/").to_i)
          end
        end
      end

      # The preset matching a cron expression, if any.
      def preset?(cron)
        PRESETS.include?(cron.to_s.strip)
      end

      private

      def number?(field)
        field.match?(/\A\d+\z/)
      end

      def single_weekday?(dow)
        dow.match?(/\A[0-7]\z/)
      end

      def day_name(dow)
        I18n.t("date.day_names")[dow.to_i % 7]
      end

      def format_time(hour, minute)
        format("%02d:%02d", hour.to_i, minute.to_i)
      end
    end
  end
end
