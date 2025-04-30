namespace :view do
  desc "Create a migration for a database view (usage: rake view:do[my_custom_view.sql])"
  task :do, [:filename] => :environment do |_t, args|
    # Ensure a filename argument is provided
    if args[:filename].nil?
      puts "Usage: rake view:do[my_custom_view.sql]"
      exit 1
    end

    # Define paths
    views_dir = "./db/views"
    migrations_dir = "./db/migrate"

    # Ensure the views directory exists
    unless Dir.exist?(views_dir)
      puts "Error: Directory '#{views_dir}' does not exist."
      exit 1
    end

    # Ensure the migrations directory exists
    unless Dir.exist?(migrations_dir)
      puts "Error: Migrations Directory '#{migrations_dir}' does not exist."
      exit 1
    end

    # Build the full path to the view file
    view_file = "#{views_dir}/#{args[:filename]}"

    # Ensure the view file exists
    unless File.exist?(view_file)
      puts "Error: View file '#{view_file}' not found."
      exit 1
    end

    # Extract the view name (remove directory path and .sql extension)
    view_name = File.basename(args[:filename], ".sql")

    # Make the ruby class name from the view name
    pascal_view_name = view_name.gsub(/(^|_)([a-z])/) { Regexp.last_match(2).upcase }

    # Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

    # Define the output migration file path
    output_file = "#{migrations_dir}/#{timestamp}_do_#{view_name}_#{timestamp}.rb"

    # Create the migration file content
    migration_content = <<~RUBY
      class Do#{pascal_view_name}#{timestamp} < ActiveRecord::Migration[5.2]
        def up
          execute <<~SQL
            DO \\$\\$
            BEGIN
                RAISE NOTICE '[%] START DROP AND CREATE VIEW', clock_timestamp();

                DROP VIEW IF EXISTS #{view_name};

                -- ------------------------------------------------------------
      #{File.read(view_file).gsub(/^/, "          ")}
                -- ------------------------------------------------------------

                RAISE NOTICE '[%] DONE CREATING VIEW', clock_timestamp();
            END \\$\\$;


          SQL
        end
      end
    RUBY

    # Write the migration file
    File.write(output_file, migration_content)

    # Notify the user
    puts "View file processed and migration created: #{output_file}"
  end
end
