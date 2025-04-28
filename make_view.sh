#!/bin/bash
# call with a full filename in the ./db/views directory
# e.g. ./make_view.sh my_custom_view.sql
# you may need to make this file executable: chmod +x make_view.sh

# Ensure a filename argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./make_view.sh <filename>"
    exit 1
fi

# Define paths
VIEWS_DIR="./db/views"
MIGRATIONS_DIR="./db/migrate"

# Ensure the views directory exists
if [ ! -d "$VIEWS_DIR" ]; then
    echo "Error: Directory '$VIEWS_DIR' does not exist."
    exit 1
fi

# Ensure the migrations directory exists
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "Error: Migrations Directory '$MIGRATIONS_DIR' does not exist."
    exit 1
fi

# Build the full path to the view file
VIEW_FILE="$VIEWS_DIR/$1"

# Ensure the view file exists
if [ ! -f "$VIEW_FILE" ]; then
    echo "Error: View file '$VIEW_FILE' not found."
    exit 1
fi

# Extract the view name (remove directory path and .sql extension)
VIEW_NAME=$(basename "$1" .sql)

# make the ruby class name from the view name
PASCAL_VIEW_NAME=$(echo "$VIEW_NAME" | sed -E 's/(^|_)([a-z])/\U\2/g')

# Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")

# Define the output migration file path
OUTPUT_FILE="$MIGRATIONS_DIR/${TIMESTAMP}_do_${VIEW_NAME}_${TIMESTAMP}.rb"


# Write the function header and start of SQL to the output file
cat <<EOF > "$OUTPUT_FILE"
class Do${PASCAL_VIEW_NAME}${TIMESTAMP} < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      DO \$\$
      BEGIN
          RAISE NOTICE '[%] START DROP AND CREATE VIEW', clock_timestamp();

          DROP VIEW IF EXISTS ${VIEW_NAME};

          -- ------------------------------------------------------------
EOF

# Append the contents of the view file
sed 's/^/          /' "$VIEW_FILE" >> "$OUTPUT_FILE"

# Append the SQL footer
cat <<EOF >> "$OUTPUT_FILE"

          -- ------------------------------------------------------------

          RAISE NOTICE '[%] DONE CREATING VIEW', clock_timestamp();
      END \$\$;


    SQL
  end
end
EOF

# Notify the user
echo "View file processed and migration created: $OUTPUT_FILE"
