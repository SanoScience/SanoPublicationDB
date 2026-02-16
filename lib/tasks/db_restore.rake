require "fileutils"

namespace :db do
  desc "Restore current env DB from pg_dump (custom format). Usage: rake 'db:restore[/path/to/file.dump]' or rake db:restore"
  task :restore, [ :dump_path ] => :environment do |_, args|
    cfg  = ActiveRecord::Base.connection_db_config.configuration_hash
    db   = cfg[:database]
    user = cfg[:username]
    host = cfg[:host] || "127.0.0.1"

    pw = ENV["PUBDB_DATABASE_PASSWORD"]
    raise "Database password ENV (PUBDB_DATABASE_PASSWORD) is not set" unless pw

    backup_dir = Rails.root.join("backups")
    dump_path  = args[:dump_path].to_s

    if dump_path.nil? || dump_path.empty?
      candidates = Dir.glob(File.join(backup_dir, "#{db}_*.dump{,.gz}")).sort_by { |p| File.mtime(p) }
      raise "No backups found for #{db} in #{backup_dir}" if candidates.empty?
      dump_path = candidates.last
    end
    raise "Dump file not found: #{dump_path}" unless File.exist?(dump_path)

    if File.extname(dump_path) == ".gz"
        tmp = Tempfile.new([ "restore", ".dump" ])
        tmp.binmode
        Zlib::GzipReader.open(dump_path) { |gz| IO.copy_stream(gz, tmp) }
        tmp.flush
        dump_path = tmp.path
    end

    puts "[Restore] Using dump: #{dump_path}"

    if Rails.env.production? && ENV["FORCE"] != "1"
      abort "Refusing to restore in production without FORCE=1"
    end

    env = { "PGPASSWORD" => pw }

    drop_args = [ "dropdb", "--if-exists", "--host", host ]
    drop_args += [ "--username", user ] if user && !user.empty?
    drop_args << db
    puts "[Restore] Dropping DB #{db}..."
    system(env, *drop_args) or abort "dropdb failed"

    create_args = [ "createdb", "--encoding", "UTF8", "--host", host ]
    create_args += [ "--username", user ] if user && !user.empty?
    create_args << db
    puts "[Restore] Creating DB #{db}..."
    system(env, *create_args) or abort "createdb failed"

    restore_args = [
      "pg_restore",
      "--format=custom",
      "--no-owner", "--no-privileges",
      "--jobs", "4",
      "--host", host,
      "--dbname", db
    ]
    restore_args += [ "--username", user ] if user && !user.empty?
    restore_args << dump_path

    puts "[Restore] Restoring into #{db}..."
    ok = system(env, *restore_args)
    raise "pg_restore failed (exit #{$?.exitstatus})" unless ok && $?.exitstatus == 0

    puts "[Restore] Done"
  ensure
    tmp&.close!
  end
end
