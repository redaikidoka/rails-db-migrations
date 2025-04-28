#!/bin/bash
# call with a full filename of a function in the ./db/triggers directory
# e.g. ./make_trigger.sh my_trigger.sql my_table
# you may need to make this file executable: chmod +x make_trigger.sh

# Ensure a filename argument is provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./make_trigger.sh <filename> <table_name>"
    exit 1
fi

# Define paths
TRIGGERS_DIR="./db/triggers"
MIGRATIONS_DIR="./db/migrate"

# Ensure the procedures directory exists
if [ ! -d "$TRIGGERS_DIR" ]; then
    echo "Error: Triggers Directory '$TRIGGERS_DIR' does not exist."
    exit 1
fi

# Ensure the migrations directory exists
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "Error: Migrations Directory '$MIGRATIONS_DIR' does not exist."
    exit 1
fi

# Build the full path to the trigger file
TRIGGER_FILE="$TRIGGERS_DIR/$1"

# Ensure the trigger file exists
if [ ! -f "$TRIGGER_FILE" ]; then
    echo "Error: Trigger file '$TRIGGER_FILE' not found."
    exit 1
fi

# Extract the trigger name (remove directory path and .sql extension)
TRIGGER_NAME=$(basename "$1" .sql)

# make the ruby class name from the trigger name
PASCAL_TRIGGER_NAME=$(echo "$TRIGGER_NAME" | sed -E 's/(^|_)([a-z])/\U\2/g')

# Get the table name
TABLE_NAME="$2"

# Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")

# Define the output migration file path
OUTPUT_FILE="$MIGRATIONS_DIR/${TIMESTAMP}_do_${TRIGGER_NAME}_${TIMESTAMP}.rb"


# Write the SQL header to the output file with dynamic trigger name
cat <<EOF > "$OUTPUT_FILE"
class Do${PASCAL_TRIGGER_NAME}${TIMESTAMP} < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      DO \$migrate\$
      BEGIN
          RAISE NOTICE '[%] START CREATE OR REPLACE TRIGGER', clock_timestamp();

          DROP TRIGGER IF EXISTS ${TRIGGER_NAME} ON ${TABLE_NAME};

          -- ------------------------------------------------------------
EOF

# Append the contents of the procedure file
sed 's/^/          /' "$TRIGGER_FILE" >> "$OUTPUT_FILE"

# Append the SQL footer
cat <<EOF >> "$OUTPUT_FILE"

          -- ------------------------------------------------------------

          RAISE NOTICE '[%] DONE CREATING TRIGGER', clock_timestamp();
      END \$migrate\$;

    SQL
  end
end
EOF

# Notify the user
echo "Trigger file processed and migration created: $OUTPUT_FILE"
