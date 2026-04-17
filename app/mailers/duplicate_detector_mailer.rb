class DuplicateDetectorMailer < ApplicationMailer
  default from: ENV["OUTLOOK_USERNAME"]

  def author_duplicates_report(groups)
    @groups = sanitize_groups(groups)
    moderator_emails = User.where(role: :moderator).pluck(:email)

    return if moderator_emails.empty? || @groups.blank?

    mail(
      to: moderator_emails,
      subject: "Suspected duplicate authors found (#{@groups.count} groups)"
    )
  end

  private

  def sanitize_groups(groups)
    Array(groups).reject(&:blank?)
  end
end
