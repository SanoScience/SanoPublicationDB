class NotificationMailer < ApplicationMailer
    helper :change_display
    default from: ENV["OUTLOOK_USERNAME"]

    def new_publication_notification(publication)
        @publication = publication
        recipients = moderator_emails
        return if recipients.empty?

        mail(
            to: recipients,
            subject: "[PubDB] New publication has been created: #{@publication.title}"
        )
    end

    def publication_update_notification(publication, user, changes_hash = {})
        @publication = publication
        @user = user
        @changes = sanitize_changes(changes_hash)

        recipients = moderator_emails
        return if recipients.empty? || @changes.blank?

        mail(
            to: recipients,
            subject: "[PubDB] Publication has been updated: #{@publication.title}"
        )
    end

    private

    def sanitize_changes(changes_hash)
        (changes_hash || {}).except(
          "updated_at"
        )
    end
end
