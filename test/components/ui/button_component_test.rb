# frozen_string_literal: true

require "test_helper"

class Ui::ButtonComponentTest < ViewComponent::TestCase
  def test_renders_an_ink_pill_button
    render_inline(Ui::ButtonComponent.new(variant: :primary)) { "Save" }

    assert_selector "button[type='button'].bg-ink", text: "Save"
  end

  def test_renders_a_link_when_href_is_given
    render_inline(Ui::ButtonComponent.new(href: "/somewhere")) { "Go" }

    assert_selector "a[href='/somewhere']", text: "Go"
  end
end
