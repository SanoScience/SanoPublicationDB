# lib/tasks/db_backup_workflow.rake
namespace :backups do
  desc "Run backup workflow and notify moderators"
  task backup_and_notify: :environment do
    result = Backups::BackupWorkflow.call
    puts "Backup workflow completed successfully: #{result.backup.outfile}"
  end
end