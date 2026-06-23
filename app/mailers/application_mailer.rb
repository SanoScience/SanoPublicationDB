class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  def moderator_emails
    User.where(role: :moderator).pluck(:email)
  end
end
