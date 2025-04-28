#!/bin/bash
# call with a full filename of a function in the ./db/procedures directory
# e.g. ./make_procedure.sh my_procedure.sql
# you may need to make this file executable: chmod +x make_procedure.sh

# Ensure a filename argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./make_procedure.sh <filename>"
    exit 1
fi

# Define paths
PROCEDURES_DIR="./db/procedures"
MIGRATIONS_DIR="./db/migrate"

# Ensure the procedures directory exists
if [ ! -d "$PROCEDURES_DIR" ]; then
    echo "Error: Procedures Directory '$PROCEDURES_DIR' does not exist."
    exit 1
fi

# Ensure the migrations directory exists
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "Error: Migrations Directory '$MIGRATIONS_DIR' does not exist."
    exit 1
fi

# Build the full path to the procedure file
PROCEDURE_FILE="$PROCEDURES_DIR/$1"

# Ensure the procedure file exists
if [ ! -f "$PROCEDURE_FILE" ]; then
    echo "Error: Procedure file '$PROCEDURE_FILE' not found."
    exit 1
fi

# Extract the stored procedure name (remove directory path and .sql extension)
PROCEDURE_NAME=$(basename "$1" .sql)

# make the ruby class name from the procedure name
PASCAL_PROCEDURE_NAME=$(echo "$PROCEDURE_NAME" | sed -E 's/(^|_)([a-z])/\U\2/g')

# Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")

# Define the output migration file path
OUTPUT_FILE="$MIGRATIONS_DIR/${TIMESTAMP}_do_${PROCEDURE_NAME}_${TIMESTAMP}.rb"


# Write the SQL header to the output file with dynamic procedure name
cat <<EOF > "$OUTPUT_FILE"
class Do${PASCAL_PROCEDURE_NAME}${TIMESTAMP} < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      DO \$migrate\$
      BEGIN
          RAISE NOTICE '[%] START CREATE OR REPLACE PROCEDURE', clock_timestamp();

          DROP PROCEDURE IF EXISTS ${PROCEDURE_NAME};

          -- ------------------------------------------------------------
EOF

# Append the contents of the procedure file
sed 's/^/          /' "$PROCEDURE_FILE" >> "$OUTPUT_FILE"

# Append the SQL footer
cat <<EOF >> "$OUTPUT_FILE"

          -- ------------------------------------------------------------

          RAISE NOTICE '[%] DONE CREATING PROCEDURE', clock_timestamp();
      END \$migrate\$;

    SQL
  end
end
EOF

# Notify the user
echo "Procedure file processed and migration created: $OUTPUT_FILE"
