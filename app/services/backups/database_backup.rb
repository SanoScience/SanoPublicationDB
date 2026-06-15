# app/services/backups/database_backup.rb
require "fileutils"

module Backups
  class DatabaseBackup
    Result = Struct.new(
      :outfile,
      :database,
      :started_at,
      :finished_at,
      :size_bytes,
      keyword_init: true
    )

    def self.call
      new.call
    end

    def call
      cfg  = ActiveRecord::Base.connection_db_config.configuration_hash
      db   = cfg[:database]
      user = cfg[:username]
      host = cfg[:host] || "127.0.0.1"

      pw = ENV["PUBDB_DATABASE_PASSWORD"]
      raise "Database password ENV (PUBDB_DATABASE_PASSWORD) is not set" unless pw

      started_at = Time.current

      timestamp  = Time.current.strftime("%Y-%m-%d_%H-%M")
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
      args += ["--username", user] if user.present?
      args << db

      File.open(outfile, "wb") do |f|
        ok = system(env, *args, out: f, err: :out)
        raise "pg_dump failed (exit #{$?.exitstatus})" unless ok && $?.success?
      end

      finished_at = Time.current

      Result.new(
        outfile: outfile.to_s,
        database: db,
        started_at: started_at,
        finished_at: finished_at,
        size_bytes: File.size(outfile)
      )
    end
  end
end