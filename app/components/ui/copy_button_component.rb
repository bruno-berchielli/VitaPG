# frozen_string_literal: true

# Small icon button that copies a given text to the clipboard.
class Ui::CopyButtonComponent < ApplicationComponent
  def initialize(text:)
    @text = text
  end
end
