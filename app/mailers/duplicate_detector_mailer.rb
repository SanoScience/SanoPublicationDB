class DuplicateDetectorMailer < ApplicationMailer
  default from: ENV["OUTLOOK_USERNAME"]

  def author_duplicates_report(groups)
    @groups = sanitize_groups(groups)
    recipients = moderator_emails
    return if recipients.empty? || @groups.blank?

    mail(
      to: recipients,
      subject: "[PubDB] Suspected duplicate authors found (#{@groups.count} groups)"
    )
  end

  private

  def sanitize_groups(groups)
    Array(groups).reject(&:blank?)
  end
end
