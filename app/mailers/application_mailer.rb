class ApplicationMailer < ActionMailer::Base
  # Must be a sender the SMTP provider accepts (e.g. a Postmark sender
  # signature); configure per install.
  default from: ENV.fetch("MAILER_FROM", "vitapg@localhost")
  layout "mailer"
end
