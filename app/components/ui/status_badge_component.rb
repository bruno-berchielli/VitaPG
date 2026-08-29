# frozen_string_literal: true

# The only way statuses are rendered anywhere in the UI: Vision-style filled
# chip (mint/coral/amber/violet) with white text.
class Ui::StatusBadgeComponent < ApplicationComponent
  STYLES = {
    pending: "bg-surface-highlight text-text-muted",
    dumping: "bg-info-strong text-white",
    uploading: "bg-info-strong text-white",
    completed: "bg-success-strong text-white",
    failed: "bg-danger-strong text-white",
    pruned: "bg-surface-highlight text-text-muted",
    enabled: "bg-success-strong text-white",
    disabled: "bg-surface-highlight text-text-muted",
    info: "bg-info-strong text-white",
    warning: "bg-warning-strong text-white",
    error: "bg-danger-strong text-white"
  }.freeze

  def initialize(status:)
    @status = status.to_sym
  end

  def label
    t(".#{@status}")
  end

  def call
    tag.span(label, class: "inline-flex items-center rounded-lg px-2.5 py-1 text-xs font-semibold #{STYLES.fetch(@status, STYLES[:pending])}")
  end
end
