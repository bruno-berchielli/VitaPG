# frozen_string_literal: true

# Default form builder: every field renders label + input + hint + error with
# the design system's classes, so form templates stay declarative.
class ApplicationFormBuilder < ActionView::Helpers::FormBuilder
  INPUT_CLASSES = "block w-full rounded-md border-border-strong bg-surface text-sm shadow-none " \
                  "placeholder:text-text-faint focus:border-primary focus:ring-primary " \
                  "disabled:cursor-not-allowed disabled:opacity-60"

  def labeled_text_field(attribute, **options) = labeled_field(:text_field, attribute, **options)
  def labeled_email_field(attribute, **options) = labeled_field(:email_field, attribute, **options)
  def labeled_number_field(attribute, **options) = labeled_field(:number_field, attribute, **options)
  def labeled_url_field(attribute, **options) = labeled_field(:url_field, attribute, **options)

  # Secrets are write-only: never render the persisted value back into the form.
  def labeled_password_field(attribute, **options)
    options[:value] = ""
    options[:autocomplete] ||= "new-password"
    options[:placeholder] ||= ("••••••••" if object&.public_send(attribute).present?)
    labeled_field(:password_field, attribute, **options)
  end

  def labeled_select(attribute, choices, label: nil, hint: nil, include_blank: false, **options)
    wrap(attribute, label:, hint:) do
      select(attribute, choices, { include_blank: include_blank },
             class: "#{INPUT_CLASSES} #{error_border(attribute)}", **options)
    end
  end

  def labeled_check_box(attribute, label: nil, hint: nil, **options)
    @template.tag.div(class: "flex items-start gap-2.5") do
      check_box(attribute, class: "mt-0.5 size-4 rounded border-border-strong text-primary focus:ring-primary", **options) +
        @template.tag.div do
          label(attribute, label || default_label(attribute), class: "text-sm font-medium") +
            (hint ? @template.tag.p(hint, class: "text-xs text-text-muted") : "".html_safe)
        end
    end
  end

  def submit_button(text = nil, **options)
    @template.render(Ui::ButtonComponent.new(variant: :primary, type: "submit", **options)) do
      text || submit_default_value
    end
  end

  private

  def labeled_field(kind, attribute, label: nil, hint: nil, **options)
    wrap(attribute, label:, hint:) do
      public_send(kind, attribute, class: "#{INPUT_CLASSES} #{error_border(attribute)} #{options.delete(:class)}", **options)
    end
  end

  def wrap(attribute, label:, hint:)
    @template.tag.div(class: "space-y-1") do
      label(attribute, label || default_label(attribute), class: "block text-sm font-medium") +
        yield +
        hint_tag(hint) +
        error_tag(attribute)
    end
  end

  def default_label(attribute)
    object&.class&.human_attribute_name(attribute) || attribute.to_s.humanize
  end

  def hint_tag(hint)
    return "".html_safe if hint.blank?

    @template.tag.p(hint, class: "text-xs text-text-muted")
  end

  def error_tag(attribute)
    messages = object&.errors&.full_messages_for(attribute)
    return "".html_safe if messages.blank?

    @template.tag.p(messages.to_sentence, class: "text-xs text-danger")
  end

  def error_border(attribute)
    "border-danger" if object&.errors&.include?(attribute)
  end
end
