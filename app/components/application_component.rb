# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ApplicationHelper
  include Turbo::FramesHelper
  include Turbo::StreamsHelper
  include ActionView::RecordIdentifier

  # Derives the Stimulus controller identifier from the component class name,
  # matching the identifier esbuild-rails assigns to the sidecar controller file.
  #
  # @return [String]
  def stimulus_controller
    controller_path = self.class.name.underscore.dasherize.gsub("/", "--")
    controller_name = controller_path.split("--").last

    "#{controller_path}--#{controller_name}"
  end

  def data_stimulus_controller
    "data-controller=#{stimulus_controller}"
  end

  def data_stimulus(suffix, target)
    "data-#{stimulus_controller}-#{suffix}=#{target}"
  end
end
