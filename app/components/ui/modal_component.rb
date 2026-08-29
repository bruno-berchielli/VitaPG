# frozen_string_literal: true

# Native <dialog> modal. The trigger slot opens it; Esc, the ✕ button and a
# backdrop click close it.
class Ui::ModalComponent < ApplicationComponent
  renders_one :trigger

  def initialize(title:)
    @title = title
  end
end
