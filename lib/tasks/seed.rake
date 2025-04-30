namespace :seed do
  desc "Create a migration for a database seed (usage: rake seed:do[my_seed.sql])"
  task :do, %i[filename] => :environment do |_t, args|
    # Ensure a filename argument is provided
    if args[:filename].nil?
      puts "Usage: rake seed:do[my_seed.sql]"
      exit 1
    end

    # Define paths
    seeds_dir = "./db/seeds"
    migrations_dir = "./db/migrate"

    # Ensure the seeds directory exists
    unless Dir.exist?(seeds_dir)
      puts "Error: Directory '#{seeds_dir}' does not exist."
      exit 1
    end

    # Build the full path to the seed file
    seed_file = "#{seeds_dir}/#{args[:filename]}"

    # Ensure the seed file exists
    unless File.exist?(seed_file)
      puts "Error: Seed file '#{seed_file}' not found."
      exit 1
    end

    # Ensure the migrations directory exists
    unless Dir.exist?(migrations_dir)
      puts "Error: Migrations Directory '#{migrations_dir}' does not exist."
      exit 1
    end

    # Extract the seed name (remove directory path and .sql extension)
    seed_name = File.basename(args[:filename], ".sql")

    # Make the ruby class name from the seed name
    pascal_seed_name = seed_name.gsub(/(^|_)([a-z])/) { Regexp.last_match(2).upcase }

    # Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

    # Define the output migration file path
    output_file = "#{migrations_dir}/#{timestamp}_do_#{seed_name}_#{timestamp}.rb"

    function_name = "Do#{pascal_seed_name}#{timestamp}"

    # Create the migration file content
    migration_content = <<~RUBY
      class #{function_name} < ActiveRecord::Migration[5.2]
        def up
          execute <<~SQL
            DO \\$\\$
            DECLARE
                row_count BIGINT;
            BEGIN
                RAISE NOTICE '[%] START SEEDING', clock_timestamp();
                SET session_replication_role = 'replica';

                -- == CLEANUP ==
                RAISE NOTICE '+++    [%] clearing records', clock_timestamp();
                DELETE FROM #{seed_name} WHERE id < 0;
                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE '>>>    [%] Rows deleted: %', CLOCK_TIMESTAMP(), row_count;
                -- == CLEANUP ==

                RAISE NOTICE '+++    [%] Seeding #{seed_name}', clock_timestamp();
                -- ------------------------------------------------------------
      #{File.read(seed_file).gsub(/^/, "          ")}
                -- ------------------------------------------------------------
                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE '>>>    [%] Rows inserted: %', CLOCK_TIMESTAMP(), row_count;
                -- ------------------------------------------------------------
                SET session_replication_role = 'origin';

                RAISE NOTICE '[%] DONE SEEDING', clock_timestamp();
            END \\$\\$;
          SQL
        end
      end
    RUBY

    # Write the migration file
    File.write(output_file, migration_content)

    # Notify the user
    puts "Seed file processed and migration created: #{output_file}"
  end
end
