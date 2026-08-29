# frozen_string_literal: true

module Notifications
  # Posts to a Slack incoming webhook (also compatible with Discord's
  # /slack-suffixed webhook URLs and Mattermost).
  class SlackNotifier < ApplicationService
    include HttpDelivery

    attr_reader :channel, :run

    def initialize(channel, run)
      @channel = channel
      @run = run
    end

    def call
      post_json!(channel.url, { text: message }.to_json)
    end

    private

    def message
      routine = run.backup_routine

      if run.completed?
        size = ActiveSupport::NumberHelper.number_to_human_size(run.size_bytes)
        ":white_check_mark: Backup *#{routine.name}* completed (#{routine.database_connection.database_name}, #{size}, #{run.duration&.round}s)"
      else
        error = run.error_message.to_s.first(300)
        ":x: Backup *#{routine.name}* FAILED (#{routine.database_connection.database_name})\n```#{error}```"
      end
    end
  end
end
