# frozen_string_literal: true

# Send emails from the application using mailer classes and views
class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'
end
