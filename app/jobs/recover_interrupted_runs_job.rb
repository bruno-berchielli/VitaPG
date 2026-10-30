# Fails runs a killed worker left in progress and removes their leftovers.
class RecoverInterruptedRunsJob < ApplicationJob
  queue_as :backups

  def perform
    Backups::InterruptedRunSweeper.call
  end
end
