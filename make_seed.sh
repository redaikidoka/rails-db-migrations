#!/bin/bash
# call with a full filename in the ./seeds directory
# e.g. ./make_seed.sh 2020-01-01_seed.sql
# you may need to make this file executable: chmod +x make_seed.sh

# Ensure a filename argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./make_seed.sh <filename>"
    exit 1
fi

# Define paths
SEEDS_DIR="./db/seeds"
MIGRATIONS_DIR="./db/migrate"

# Ensure the seeds directory exists
if [ ! -d "$SEEDS_DIR" ]; then
    echo "Error: Directory '$SEEDS_DIR' does not exist."
    exit 1
fi

# Build the full path to the seed file
SEED_FILE="$SEEDS_DIR/$1"

# Ensure the seed file exists
if [ ! -f "$SEED_FILE" ]; then
    echo "Error: Seed file '$SEED_FILE' not found."
    exit 1
fi

# Ensure the migrations directory exists
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "Error: Migrations Directory '$MIGRATIONS_DIR' does not exist."
    exit 1
fi


# Extract the seed name (remove directory path and .sql extension)
SEED_NAME=$(basename "$1" .sql)

# make the ruby class name from the seed name
PASCAL_SEED_NAME=$(echo "$SEED_NAME" | sed -E 's/(^|_)([a-z])/\U\2/g')


# Get the current timestamp in UTC (YYYYMMDDHHMMSS format)
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")

# Define the output migration file path
OUTPUT_FILE="$MIGRATIONS_DIR/${TIMESTAMP}_do_${SEED_NAME}_${TIMESTAMP}.rb"

FUNCTION_NAME="Do${PASCAL_SEED_NAME}${TIMESTAMP}"
# Write the SQL header to the output file
cat <<EOF > "$OUTPUT_FILE"
class ${FUNCTION_NAME} < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      DO \$\$
      DECLARE
          row_count BIGINT;
      BEGIN
          RAISE NOTICE '[%] START SEEDING', clock_timestamp();
          SET session_replication_role = 'replica';

          -- == CLEANUP ==
          RAISE NOTICE '+++    [%] clearing records', clock_timestamp();
          DELETE FROM ${SEED_NAME} WHERE id < 0;
          GET DIAGNOSTICS row_count = ROW_COUNT;
          RAISE NOTICE '>>>    [%] Rows deleted: %', CLOCK_TIMESTAMP(), row_count;
          -- == CLEANUP ==

          RAISE NOTICE '+++    [%] Seeding ${SEED_NAME}', clock_timestamp();
          -- ------------------------------------------------------------
EOF

# Append the contents of the seed file
sed 's/^/          /' "$SEED_FILE" >> "$OUTPUT_FILE"

# Append the SQL footer
cat <<EOF >> "$OUTPUT_FILE"
          -- ------------------------------------------------------------
          GET DIAGNOSTICS row_count = ROW_COUNT;
          RAISE NOTICE '>>>    [%] Rows inserted: %', CLOCK_TIMESTAMP(), row_count;
          -- ------------------------------------------------------------
          SET session_replication_role = 'origin';

          RAISE NOTICE '[%] DONE SEEDING', clock_timestamp();
      END \$\$;
    SQL
  end
end
EOF

# Notify the user
echo "Seed file processed and migration created: $OUTPUT_FILE"
