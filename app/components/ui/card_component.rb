# frozen_string_literal: true

class Ui::CardComponent < ApplicationComponent
  def initialize(padding: true, classes: "", **html_attributes)
    @padding = padding
    @classes = classes
    @html_attributes = html_attributes
  end

  def card_classes
    [
      "rounded-lg border border-border bg-surface",
      (@padding ? "p-5" : nil),
      @classes
    ].compact.join(" ")
  end

  def call
    tag.div(content, class: card_classes, **@html_attributes)
  end
end
