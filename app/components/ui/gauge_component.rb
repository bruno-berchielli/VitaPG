# frozen_string_literal: true

# Vision's donut gauge: thick white ring on the hero surface, big percentage
# in the middle. Pure inline SVG.
class Ui::GaugeComponent < ApplicationComponent
  RADIUS = 42
  CIRCUMFERENCE = (2 * Math::PI * RADIUS)

  # @param percent [Numeric] 0..100
  def initialize(percent:, label:, caption: nil, tip: nil)
    @percent = percent.to_f.clamp(0, 100)
    @label = label
    @caption = caption
    @tip = tip
  end

  def tip = @tip

  def dash_filled
    (CIRCUMFERENCE * @percent / 100).round(2)
  end

  def circumference
    CIRCUMFERENCE.round(2)
  end

  def percent_text
    "#{@percent.round}%"
  end
end
