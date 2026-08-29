# frozen_string_literal: true

class BackupRuns::LogLineComponent < ApplicationComponent
  COLORS = {
    "info" => "text-gray-300",
    "warning" => "text-amber-400",
    "error" => "text-red-400"
  }.freeze

  def initialize(log:)
    @log = log
  end

  def call
    tag.li(class: "flex gap-3 font-mono text-xs leading-5") do
      tag.span(@log.created_at.strftime("%H:%M:%S"), class: "shrink-0 tabular-nums text-gray-500") +
        tag.span(message_text, class: "whitespace-pre-wrap break-all #{COLORS.fetch(@log.status, 'text-gray-300')}")
    end
  end

  private

  def message_text
    @log.message.is_a?(String) ? @log.message : @log.message.to_json
  end
end
