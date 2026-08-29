# frozen_string_literal: true

# Small "i" trigger with a pure-CSS tooltip bubble (hover and keyboard focus),
# for context that would clutter the layout as permanent text.
class Ui::InfoTipComponent < ApplicationComponent
  def initialize(text:)
    @text = text
  end

  def call
    tag.span(class: "group relative inline-flex align-middle") do
      trigger + bubble
    end
  end

  private

  def trigger
    tag.button(
      render(Ui::IconComponent.new(:info, classes: "size-4")),
      type: "button",
      "aria-label": @text,
      class: "cursor-help rounded-full text-text-faint transition-colors hover:text-text-main " \
             "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ink"
    )
  end

  def bubble
    tag.span(role: "tooltip",
             class: "pointer-events-none invisible absolute bottom-full left-1/2 z-40 mb-2.5 w-64 -translate-x-1/2 " \
                    "translate-y-1 rounded-xl bg-ink px-3.5 py-2.5 text-left text-xs font-medium leading-relaxed " \
                    "text-on-ink opacity-0 shadow-pop transition-all duration-150 " \
                    "group-hover:visible group-hover:translate-y-0 group-hover:opacity-100 " \
                    "group-focus-within:visible group-focus-within:translate-y-0 group-focus-within:opacity-100") do
      safe_join([
        @text,
        tag.span(class: "absolute left-1/2 top-full size-2 -translate-x-1/2 -translate-y-1 rotate-45 bg-ink")
      ])
    end
  end
end
