class NotificationMailer < ApplicationMailer
    helper :application
    default from: ENV["OUTLOOK_USERNAME"]

    def new_publication_notification(publication)
        @publication = publication
        moderator_emails = User.where(role: :moderator).pluck(:email)

        return if moderator_emails.empty?

        mail(
            to: moderator_emails,
            subject: "New publication has been created: #{@publication.title}"
        )
    end

    def publication_update_notification(publication, changes_hash = {})
        @publication = publication
        @changes = sanitize_changes(changes_hash)

        moderator_emails = User.where(role: :moderator).pluck(:email)
        return if moderator_emails.empty? || @changes.blank?

        mail(
            to: moderator_emails,
            subject: "Publication has been updated: #{@publication.title}"
        )
    end

    private

    def sanitize_changes(changes_hash)
        (changes_hash || {}).except(
          "updated_at"
        )
    end
end
