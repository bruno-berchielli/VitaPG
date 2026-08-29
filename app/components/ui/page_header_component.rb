# frozen_string_literal: true

class Ui::PageHeaderComponent < ApplicationComponent
  renders_many :actions

  def initialize(title:, description: nil)
    @title = title
    @description = description
  end
end
