# frozen_string_literal: true

module Backups
  # Raised inside a run once someone asked to cancel it.
  class Canceled < Error
    def initialize(message = "Backup canceled")
      super
    end
  end
end
