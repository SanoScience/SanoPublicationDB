# lib/tasks/db_backup.rake
namespace :db do
  desc "Backup current environment DB with pg_dump (custom format)"
  task backup: :environment do
    result = Backups::DatabaseBackup.call
    puts "Wrote backup to #{result.outfile}"
  end
end
