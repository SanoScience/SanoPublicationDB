# app/services/backups/backup_workflow.rb
require "fileutils"

module Backups
  class BackupWorkflow
    KEEP_LAST = 15

    Result = Struct.new(
      :backup,
      :deleted_files,
      :started_at,
      :finished_at,
      keyword_init: true
    )

    def self.call
      new.call
    end

    def call
      started_at = Time.current
      stage = :initialization
      backup = nil

      stage = :backup
      backup = Backups::DatabaseBackup.call

      stage = :sync
      sync_backups!

      stage = :cleanup
      deleted_files = cleanup_old_backups!

      finished_at = Time.current
      write_success_marker!(finished_at)

      result = Result.new(
        backup: backup,
        deleted_files: deleted_files,
        started_at: started_at,
        finished_at: finished_at
      )

      stage = :success_email
      BackupMailer.backup_success(result)&.deliver_now!

      result
    rescue => e
      notify_failure(stage: stage, error: e, started_at: started_at, backup: backup)
      raise
    end

    private

    def sync_backups!
      link = ENV["AZCOPY_LINK"]
      raise "AZCOPY_LINK is not set" if link.blank?

      backup_dir = Rails.root.join("backups").to_s
      ok = system("azcopy", "sync", "#{backup_dir}/", link)
      raise "azcopy sync failed (exit #{$?.exitstatus})" unless ok && $?.success?
    end

    def cleanup_old_backups!
      backup_dir = Rails.root.join("backups")
      FileUtils.mkdir_p(backup_dir)

      files = Dir.glob(backup_dir.join("*.dump")).sort_by { |file| File.mtime(file) }.reverse
      files_to_delete = files.drop(KEEP_LAST)

      files_to_delete.each { |file| File.delete(file) }

      files_to_delete.map { |file| File.basename(file) }
    end

    def write_success_marker!(time)
      marker = Rails.root.join("tmp", "last_backup_success_at")
      FileUtils.mkdir_p(marker.dirname)
      File.write(marker, time.to_i.to_s)
    end

    def notify_failure(stage:, error:, started_at:, backup:)
      BackupMailer.backup_failure(
        stage: stage,
        error: error,
        started_at: started_at,
        backup: backup
      )&.deliver_now
    rescue => mail_error
      Rails.logger.error(
        "[BackupWorkflow] failure email could not be sent. " \
        "original_error=#{error.class}: #{error.message}; " \
        "mailer_error=#{mail_error.class}: #{mail_error.message}"
      )
    end
  end
end