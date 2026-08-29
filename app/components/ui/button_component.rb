# frozen_string_literal: true

class Ui::ButtonComponent < ApplicationComponent
  VARIANTS = {
    primary: "bg-primary text-white hover:bg-primary-hover focus-visible:ring-primary",
    secondary: "border border-border-strong bg-surface text-text-main hover:bg-surface-highlight focus-visible:ring-primary",
    danger: "bg-danger text-white hover:opacity-90 focus-visible:ring-danger",
    ghost: "text-text-muted hover:bg-surface-highlight hover:text-text-main focus-visible:ring-primary"
  }.freeze

  SIZES = {
    sm: "px-2.5 py-1.5 text-xs",
    md: "px-3.5 py-2 text-sm"
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
      "inline-flex cursor-pointer items-center justify-center gap-1.5 rounded-md font-medium",
      "transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-1",
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
