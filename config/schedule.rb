# by default backups database every 3 days at 18:00 and deletes old backups after 15 days
# if you want to change this, you can do it by editing the schedule.rb file

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

every 3.days, at: "18:00" do
    command "cd #{path}/backups && ls -1t *.dump | tail -n +16 | xargs -r rm --"
end

every 3.days, at: "18:05" do
    rake "db:backup"
end

every 3.days, at: "18:10" do
    command "azcopy sync #{path}/backups/ \"$AZCOPY_LINK\""
end

every :monday, at: "09:00" do
  rake "authors:report_duplicates"
end
