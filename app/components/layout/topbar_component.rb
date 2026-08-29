# frozen_string_literal: true

class Layout::TopbarComponent < ApplicationComponent
  def initialize(query: nil)
    @query = query
  end

  def query = @query

  def today
    helpers.l(Date.current, format: :long)
  end
end
