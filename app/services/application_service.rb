class ApplicationService
  include ActiveModel::Validations

  def self.call(*args)
    new(*args).call
  end

  def call
    raise NotImplementedError, "You must implement the call method"
  end

  def initialize(*args)
    @args = args
  end

  def call
    raise NotImplementedError, "You must implement the call method"
  end

  def valid?
    super && errors.empty?
  end

  def errors
    @errors ||= ActiveModel::Errors.new(self)
  end

  private

  def log_info(message)
    puts "[INFO] #{message}"
    backup_run.log!(message: { message: message }, status: :info)
  end

  def log_error(message)
    puts "[ERROR] #{message}"
    backup_run.log!(message: { message: message }, status: :error)
  end

  def log_output(output)
    output.each_line do |line|
      line = line.strip
      next if line.empty?

      puts "[OUTPUT] #{line}"
      backup_run.log!(message: { output: line }, status: :info)
    end
  end
end
