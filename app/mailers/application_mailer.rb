# frozen_string_literal: true

# Parent class for all Mailers. Sets defaults.
class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'
end
