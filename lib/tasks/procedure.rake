namespace :procedure do
  desc "Create a migration for a database procedure (usage: rake procedure:do[my_procedure.sql])"
  task :do, [:filename] => :environment do |_t, args|
    # Ensure a filename argument is provided
    if args[:filename].nil?
      puts "Usage: rake procedure:do[my_procedure.sql]"
      exit 1
    end

    # Define paths
    procedures_dir = "./db/procedures"
    migrations_dir = "./db/migrate"

    # Ensure the procedures directory exists
    unless Dir.exist?(procedures_dir)
      puts "Error: Procedures Directory '#{procedures_dir}' does not exist."
      exit 1
    end

    # Ensure the migrations directory exists
    unless Dir.exist?(migrations_dir)
      puts "Error: Migrations Directory '#{migrations_dir}' does not exist."
      exit 1
    end

    # Build the full path to the procedure file
    procedure_file = "#{procedures_dir}/#{args[:filename]}"

    # Ensure the procedure file exists
    unless File.exist?(procedure_file)
      puts "Error: Procedure file '#{procedure_file}' not found."
      exit 1
    end

    # Extract the stored procedure name (remove directory path and .sql extension)
    procedure_name = File.basename(args[:filename], ".sql")

    # Make the ruby class name from the procedure name
    pascal_procedure_name = procedure_name.gsub(/(^|_)([a-z])/) { Regexp.last_match(2).upcase }

    # Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

    # Define the output migration file path
    output_file = "#{migrations_dir}/#{timestamp}_do_#{procedure_name}_#{timestamp}.rb"

    # Create the migration file content
    migration_content = <<~RUBY
      class Do#{pascal_procedure_name}#{timestamp} < ActiveRecord::Migration[5.2]
        def up
          execute <<~SQL
            DO \\$migrate\\$
            BEGIN
                RAISE NOTICE '[%] START CREATE OR REPLACE PROCEDURE', clock_timestamp();

                DROP PROCEDURE IF EXISTS #{procedure_name};

                -- ------------------------------------------------------------
      #{File.read(procedure_file).gsub(/^/, "          ")}
                -- ------------------------------------------------------------

                RAISE NOTICE '[%] DONE CREATING PROCEDURE', clock_timestamp();
            END \\$migrate\\$;

          SQL
        end
      end
    RUBY

    # Write the migration file
    File.write(output_file, migration_content)

    # Notify the user
    puts "Procedure file processed and migration created: #{output_file}"
  end
end
