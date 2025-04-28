#!/bin/bash
# call with a full filename of a function in the ./db/functions directory
# e.g. ./make_function.sh my_function.sql
# you may need to make this file executable: chmod +x make_function.sh

# Ensure a filename argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./make_function.sh <filename>"
    exit 1
fi

# Define paths
FUNCTIONS_DIR="./db/functions"
MIGRATIONS_DIR="./db/migrate"

# Ensure the functions directory exists
if [ ! -d "$FUNCTIONS_DIR" ]; then
    echo "Error: Functions Directory '$FUNCTIONS_DIR' does not exist."
    exit 1
fi

# Ensure the migrations directory exists
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "Error: Migrations Directory '$MIGRATIONS_DIR' does not exist."
    exit 1
fi

# Build the full path to the function file
FUNCTION_FILE="$FUNCTIONS_DIR/$1"

# Ensure the function file exists
if [ ! -f "$FUNCTION_FILE" ]; then
    echo "Error: Function file '$FUNCTION_FILE' not found."
    exit 1
fi

# Extract the stored procedure name (remove directory path and .sql extension)
FUNCTION_NAME=$(basename "$1" .sql)

# make the ruby class name from the function name
PASCAL_FUNCTION_NAME=$(echo "$FUNCTION_NAME" | sed -E 's/(^|_)([a-z])/\U\2/g')

# Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")

# Define the output migration file path
OUTPUT_FILE="$MIGRATIONS_DIR/${TIMESTAMP}_do_${FUNCTION_NAME}_${TIMESTAMP}.rb"


# Write the SQL header to the output file with dynamic procedure name
cat <<EOF > "$OUTPUT_FILE"
class Do${PASCAL_FUNCTION_NAME}${TIMESTAMP} < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      DO \$migrate\$
      BEGIN
          RAISE NOTICE '[%] START CREATE OR REPLACE FUNCTION', clock_timestamp();

          DROP FUNCTION IF EXISTS ${FUNCTION_NAME};

          -- ------------------------------------------------------------
EOF

# Append the contents of the function file
sed 's/^/          /' "$FUNCTION_FILE" >> "$OUTPUT_FILE"

# Append the SQL footer
cat <<EOF >> "$OUTPUT_FILE"

          -- ------------------------------------------------------------

          RAISE NOTICE '[%] DONE CREATING FUNCTION', clock_timestamp();
      END \$migrate\$;

    SQL
  end
end
EOF

# Notify the user
echo "Function file processed and migration created: $OUTPUT_FILE"
