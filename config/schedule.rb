# by default backups database every 3 days at 18:00 and deletes old backups after 15 days
# if you want to change this, you can do it by editing the schedule.rb file

set :output, "log/cron.log"
env :PATH, ENV["PATH"]
env :PUBDB_DATABASE_PASSWORD, ENV["PUBDB_DATABASE_PASSWORD"]

every 3.days, at: "18:00" do
    command "cd #{path}/backups && ls -1t *.dump | tail -n +16 | xargs -r rm --"
    rake "db:backup"
end
