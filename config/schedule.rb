# Backup workflow frequency is scheduled using BACKUP_INTERVAL variable and keeps the latest 15 dump files.
# if you want to change file amount, you can do it by editing the services/backups/backup_workflow.rb file

set :output, "#{path}/log/cron.log"

ENV_KEYS = %w[
  PATH
  RAILS_ENV
  BUNDLE_PATH
  BUNDLE_APP_CONFIG
  BUNDLE_DEPLOYMENT
  BUNDLE_WITHOUT
  RAILS_MASTER_KEY
  SECRET_KEY_BASE
  PUBDB_DATABASE_HOST
  PUBDB_DATABASE_USERNAME
  PUBDB_DATABASE_PASSWORD
  OUTLOOK_USERNAME
  OUTLOOK_PASSWORD
  AZCOPY_LINK
].freeze

ENV_KEYS.each do |key|
  value = ENV[key].to_s
  env key.to_sym, value unless value.empty?
end

backup_interval_days = ENV.fetch("BACKUP_INTERVAL", "3").to_i

every backup_interval_days.days, at: "18:05" do
  rake "backups:backup_and_notify"
end

every :monday, at: "09:00" do
  rake "authors:report_duplicates"
end

every 1.month, at: "start of the month at 3:00 am" do
  rake "openalex_citations:refresh"
end
