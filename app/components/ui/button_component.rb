# frozen_string_literal: true

class Ui::ButtonComponent < ApplicationComponent
  # Vision signature: the primary action is an "ink" pill — black on the light
  # theme, white on the dark theme.
  VARIANTS = {
    primary: "bg-ink text-on-ink hover:opacity-85 focus-visible:ring-ink",
    secondary: "border border-border-strong bg-surface text-text-main hover:bg-surface-highlight focus-visible:ring-ink",
    danger: "bg-danger-strong text-white hover:opacity-85 focus-visible:ring-danger",
    ghost: "text-text-muted hover:bg-surface-highlight hover:text-text-main focus-visible:ring-ink",
    hero: "bg-white text-[#101114] hover:opacity-85 focus-visible:ring-white"
  }.freeze

  SIZES = {
    sm: "px-3.5 py-1.5 text-xs",
    md: "px-5 py-2.5 text-sm"
  }.freeze

  renders_one :leading_icon

  # @param href [String, nil] renders a link when present, a button otherwise
  def initialize(variant: :secondary, size: :md, href: nil, method: nil, **html_attributes)
    @variant = variant.to_sym
    @size = size.to_sym
    @href = href
    @method = method
    @html_attributes = html_attributes
  end

  def classes
    [
      "inline-flex cursor-pointer items-center justify-center gap-1.5 rounded-full font-semibold",
      "transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-1",
      "disabled:cursor-not-allowed disabled:opacity-50",
      VARIANTS.fetch(@variant),
      SIZES.fetch(@size),
      @html_attributes[:class]
    ].compact.join(" ")
  end

  def link?
    @href.present?
  end

  def attributes
    attrs = @html_attributes.except(:class)
    if link? && @method
      attrs[:data] = (attrs[:data] || {}).merge(turbo_method: @method)
    end
    attrs
  end
end
