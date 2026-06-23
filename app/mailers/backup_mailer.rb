# app/mailers/backup_mailer.rb
class BackupMailer < ApplicationMailer
  default from: ENV["OUTLOOK_USERNAME"]

  def backup_success(result)
    recipients = moderator_emails
    return if recipients.empty?

    mail(
      to: recipients,
      subject: "[PubDB] Backup succeeded: #{File.basename(result.backup.outfile)}",
      body: success_body(result),
      content_type: "text/plain; charset=UTF-8"
    )
  end

  def backup_failure(stage:, error:, started_at:, backup: nil)
    recipients = moderator_emails
    return if recipients.empty?

    mail(
      to: recipients,
      subject: "[PubDB] Backup FAILED at stage: #{stage}",
      body: failure_body(stage: stage, error: error, started_at: started_at, backup: backup),
      content_type: "text/plain; charset=UTF-8"
    )
  end

  private

  def success_body(result)
    duration = (result.finished_at - result.started_at).round(2)
    size_mb = (result.backup.size_bytes.to_f / 1.megabyte).round(2)

    <<~TEXT
      Backup workflow completed successfully.

      Database: #{result.backup.database}
      File: #{result.backup.outfile}
      Size: #{size_mb} MB
      Started at: #{result.started_at}
      Finished at: #{result.finished_at}
      Duration: #{duration} s

      Deleted old backups: #{result.deleted_files.size}
      #{result.deleted_files.any? ? "Deleted files: #{result.deleted_files.join(', ')}" : "Deleted files: none"}
    TEXT
  end

  def failure_body(stage:, error:, started_at:, backup:)
    backtrace = Array(error.backtrace).first(10).join("\n")
    backup_info =
      if backup.present?
        "Partial backup file: #{backup.outfile}\n"
      else
        "Partial backup file: none\n"
      end

    <<~TEXT
      Backup workflow failed.

      Stage: #{stage}
      Started at: #{started_at}
      Error class: #{error.class}
      Error message: #{error.message}
      #{backup_info}
      Backtrace:
      #{backtrace}
    TEXT
  end
end
