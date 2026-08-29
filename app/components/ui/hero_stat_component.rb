# frozen_string_literal: true

# Vision's signature stat card: glossy black surface, small tracking label,
# huge display numeral, optional delta chip + caption.
class Ui::HeroStatComponent < ApplicationComponent
  def initialize(label:, value:, caption: nil, delta: nil, delta_kind: :success)
    @label = label
    @value = value
    @caption = caption
    @delta = delta
    @delta_kind = delta_kind
  end

  def delta_classes
    case @delta_kind
    when :danger then "bg-danger-strong text-white"
    when :neutral then "bg-white/15 text-white"
    else "bg-success-strong text-white"
    end
  end
end
