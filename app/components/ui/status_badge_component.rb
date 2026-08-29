# frozen_string_literal: true

# The only way statuses are rendered anywhere in the UI: solid dot + label.
class Ui::StatusBadgeComponent < ApplicationComponent
  STYLES = {
    pending: { dot: "bg-text-faint", text: "text-text-muted" },
    dumping: { dot: "bg-info", text: "text-info" },
    uploading: { dot: "bg-info", text: "text-info" },
    completed: { dot: "bg-success", text: "text-success" },
    failed: { dot: "bg-danger", text: "text-danger" },
    pruned: { dot: "bg-text-faint", text: "text-text-muted" },
    enabled: { dot: "bg-success", text: "text-success" },
    disabled: { dot: "bg-text-faint", text: "text-text-muted" },
    info: { dot: "bg-info", text: "text-info" },
    warning: { dot: "bg-warning", text: "text-warning" },
    error: { dot: "bg-danger", text: "text-danger" }
  }.freeze

  def initialize(status:)
    @status = status.to_sym
  end

  def style
    STYLES.fetch(@status, STYLES[:pending])
  end

  def label
    t(".#{@status}")
  end

  def call
    tag.span(class: "inline-flex items-center gap-1.5 text-xs font-medium #{style[:text]}") do
      tag.span(class: "size-1.5 rounded-full #{style[:dot]}") + label
    end
  end
end
