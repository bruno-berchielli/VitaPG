Rails.application.config.to_prepare do
  ActionView::Base.default_form_builder = ApplicationFormBuilder
end
