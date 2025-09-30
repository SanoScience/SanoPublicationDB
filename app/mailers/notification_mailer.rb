class NotificationMailer < ApplicationMailer
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
end
