# frozen_string_literal: true

class Ui::FlashComponent < ApplicationComponent
  STYLES = {
    notice: { icon: :check_circle, classes: "border-success/30 text-success" },
    alert: { icon: :warning, classes: "border-danger/30 text-danger" }
  }.freeze

  def initialize(flash:)
    @flash = flash
  end

  def items
    @flash.to_h.filter_map do |type, message|
      next if message.blank?

      style = STYLES[type.to_sym] || STYLES[:notice]
      { message: message, icon: style[:icon], classes: style[:classes] }
    end
  end

  def render?
    items.any?
  end
end
