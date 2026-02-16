require "fileutils"

namespace :db do
  desc "Backup current environment DB with pg_dump (custom format)"
  task backup: :environment do
    cfg = ActiveRecord::Base.connection_db_config.configuration_hash
    db   = cfg[:database]
    user = cfg[:username]
    host = cfg[:host] || "127.0.0.1"

    pw = ENV["PUBDB_DATABASE_PASSWORD"]
    raise "Database password ENV (PUBDB_DATABASE_PASSWORD) is not set" unless pw

    timestamp  = Time.now.strftime("%Y-%m-%d_%H-%M")
    backup_dir = Rails.root.join("backups")
    FileUtils.mkdir_p(backup_dir)
    outfile = backup_dir.join("#{db}_#{timestamp}.dump")

    env  = { "PGPASSWORD" => pw }
    args = [
      "pg_dump",
      "--format=custom", "--compress=9",
      "--no-owner", "--no-privileges",
      "--host", host
    ]
    args += [ "--username", user ] if user && !user.empty?
    args << db

    File.open(outfile, "wb") do |f|
      ok = system(env, *args, out: f, err: :out)
      raise "pg_dump failed (exit #{$?.exitstatus})" unless ok && $?.exitstatus == 0
    end

    puts "[Backup] Wrote #{outfile}"
  end
end
