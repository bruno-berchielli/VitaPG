class ApplicationService
  include ActiveModel::Validations

  def self.call(*args)
    new(*args).call
  end

  def call
    raise NotImplementedError, "You must implement the call method"
  end

  private

  def log_info(message)
    backup_run.log!(message:, status: :info)
  end

  def log_error(message)
    backup_run.log!(message:, status: :error)
  end

  def log_progress(current_part, total_parts)
    return if total_parts < 4

    milestones = {
      25 => (total_parts * 0.25).ceil,
      50 => (total_parts * 0.50).ceil,
      75 => (total_parts * 0.75).ceil,
      100 => total_parts
    }

    milestones.each do |percent, part_number|
      if current_part >= part_number && !@progress_logged.include?(percent)
        log_info("Upload progress: #{percent}%")
        @progress_logged.add(percent)
      end
    end
  end
end
