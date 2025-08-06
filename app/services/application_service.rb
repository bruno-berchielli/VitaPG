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
end
