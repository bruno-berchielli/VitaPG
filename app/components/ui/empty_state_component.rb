# frozen_string_literal: true

class Ui::EmptyStateComponent < ApplicationComponent
  renders_one :action

  def initialize(icon:, title:, description:)
    @icon = icon
    @title = title
    @description = description
  end
end
