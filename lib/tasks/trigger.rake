namespace :trigger do
  desc "Create a migration for a database trigger (usage: rake trigger:do[my_trigger.sql,my_table])"
  task :do, %i[filename table_name] => :environment do |_t, args|
    # Ensure filename and table_name arguments are provided
    if args[:filename].nil? || args[:table_name].nil?
      puts "Usage: rake trigger:do[my_trigger.sql,my_table]"
      exit 1
    end

    # Define paths
    triggers_dir = "./db/triggers"
    migrations_dir = "./db/migrate"

    # Ensure the triggers directory exists
    unless Dir.exist?(triggers_dir)
      puts "Error: Triggers Directory '#{triggers_dir}' does not exist."
      exit 1
    end

    # Ensure the migrations directory exists
    unless Dir.exist?(migrations_dir)
      puts "Error: Migrations Directory '#{migrations_dir}' does not exist."
      exit 1
    end

    # Build the full path to the trigger file
    trigger_file = "#{triggers_dir}/#{args[:filename]}"

    # Ensure the trigger file exists
    unless File.exist?(trigger_file)
      puts "Error: Trigger file '#{trigger_file}' not found."
      exit 1
    end

    # Extract the trigger name (remove directory path and .sql extension)
    trigger_name = File.basename(args[:filename], ".sql")

    # Make the ruby class name from the trigger name
    pascal_trigger_name = trigger_name.gsub(/(^|_)([a-z])/) { Regexp.last_match(2).upcase }

    # Get the table name
    table_name = args[:table_name]

    # Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

    # Define the output migration file path
    output_file = "#{migrations_dir}/#{timestamp}_do_#{trigger_name}_#{timestamp}.rb"

    # Create the migration file content
    migration_content = <<~RUBY
      class Do#{pascal_trigger_name}#{timestamp} < ActiveRecord::Migration[5.2]
        def up
          execute <<~SQL
            DO \\$migrate\\$
            BEGIN
                RAISE NOTICE '[%] START CREATE OR REPLACE TRIGGER', clock_timestamp();

                DROP TRIGGER IF EXISTS #{trigger_name} ON #{table_name};

                -- ------------------------------------------------------------
      #{File.read(trigger_file).gsub(/^/, "          ")}
                -- ------------------------------------------------------------

                RAISE NOTICE '[%] DONE CREATING TRIGGER', clock_timestamp();
            END \\$migrate\\$;

          SQL
        end
      end
    RUBY

    # Write the migration file
    File.write(output_file, migration_content)

    # Notify the user
    puts "Trigger file processed and migration created: #{output_file}"
  end
end
