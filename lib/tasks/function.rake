namespace :function do
  desc "Create a migration for a database function (usage: rake function:do[my_function.sql])"
  task :do, [:filename] => :environment do |_t, args|
    # Ensure a filename argument is provided
    if args[:filename].nil?
      puts "Usage: rake function:do[my_function.sql]"
      exit 1
    end

    # Define paths
    functions_dir = "./db/functions"
    migrations_dir = "./db/migrate"

    # Ensure the functions directory exists
    unless Dir.exist?(functions_dir)
      puts "Error: Functions Directory '#{functions_dir}' does not exist."
      exit 1
    end

    # Ensure the migrations directory exists
    unless Dir.exist?(migrations_dir)
      puts "Error: Migrations Directory '#{migrations_dir}' does not exist."
      exit 1
    end

    # Build the full path to the function file
    function_file = "#{functions_dir}/#{args[:filename]}"

    # Ensure the function file exists
    unless File.exist?(function_file)
      puts "Error: Function file '#{function_file}' not found."
      exit 1
    end

    # Extract the stored procedure name (remove directory path and .sql extension)
    function_name = File.basename(args[:filename], ".sql")

    # Make the ruby class name from the function name
    pascal_function_name = function_name.gsub(/(^|_)([a-z])/) { Regexp.last_match(2).upcase }

    # Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

    # Define the output migration file path
    output_file = "#{migrations_dir}/#{timestamp}_do_#{function_name}_#{timestamp}.rb"

    # Create the migration file content
    migration_content = <<~RUBY
      class Do#{pascal_function_name}#{timestamp} < ActiveRecord::Migration[5.2]
        def up
          execute <<~SQL
            DO \\$migrate\\$
            BEGIN
                RAISE NOTICE '[%] START CREATE OR REPLACE FUNCTION', clock_timestamp();

                DROP FUNCTION IF EXISTS #{function_name};

                -- ------------------------------------------------------------
      #{File.read(function_file).gsub(/^/, "          ")}
                -- ------------------------------------------------------------

                RAISE NOTICE '[%] DONE CREATING FUNCTION', clock_timestamp();
            END \\$migrate\\$;

          SQL
        end
      end
    RUBY

    # Write the migration file
    File.write(output_file, migration_content)

    # Notify the user
    puts "Function file processed and migration created: #{output_file}"
  end
end
