# rails-db-migrations

Quick sample tools for managing migrations for sql objects like views, procedures, triggers, functions and seeds.
After multiple attempts to use numbered migrations, we decided to use a different approach.

## Background: Versioning DB Objects

If you use Ruby on Rails, you probably use ActiveRecord migrations to manage your database schema. They're in general, great.
Additional gem tools like [fx](https://github.com/teoljungberg/fx) and [Scenic](https://github.com/scenic-views/scenic) are available to manage database functions and views. They don't support triggers, procedures and seeds.

The vision for having numbered versions of all your database objects accrete inside your project doesn't work for our team at Gemini. It also doesn't give us the ability to easily see and review changes in Github Pull Requests.

## Decisions Guiding Our Solution

Our Goals:

- no accumulation of numbered database objects in the project
- ability to see and review changes in Github Pull Requests
- simple, fast and easy to invoke

## Solution

We made a little cluster of shell scripts (I know, not a very Ruby solution, but clean, clear and fast):

- `make_function.sh`
- `make_procedure.sh`
- `make_trigger.sh`
- `make_seed.sh`
- `make_view.sh`

that look for db object definitions the `db/` folders for each specific object:

- `db/views/`
- `db/functions/`
- `db/procedures/`
- `db/triggers/`
- `db/seeds/`

### INSTALLATION

1. Copy the shell scripts into the root of your rails project.
2. Create the related db folders: `mkdir db/functions db/procedures db/triggers db/seeds db/views`
3. Make the shell scripts executable: `chmod +x make_function.sh make_procedure.sh make_trigger.sh make_seed.sh make_view.sh`

### Usage

In general, when you want to update or create a database object, you

1. create or edit the file, for example `db/functions/whee.sql` to create / update the function `whee()`
2. If this is your first time working with functions, make the shell script executable with `chmod +x make_function.sh`
3. Create the migration with `./make_function.sh whee.sql`

This will generate a migration file in `db/migrate/` with a unique naming scheme that you can run with `rails db:migrate`.

#### SETUP

1. Copy the migration file `db/migrations/20250428183925_setup_happy.rb` into your project.
2. Run `rails db:migrate` to create the table.
3. Copy the seed file `db/seeds/happies.sql` into your project.
4. Copy the procedures file, `db/procedures/fun.sql`, into your project.
5. Copy the functions file, `db/functions/whee.sql`, into your project.
6. Copy the views file, `db/views/happy_view.sql`, into your project.
7. Copy the triggers file, `db/triggers/trbiu_voucher_sessions.sql`, into your project.

#### PROCEDURE

1. Verify the procedure file looks like `db/procedures/fun.sql` :

```
CREATE PROCEDURE fun()  LANGUAGE plpgsql
AS $$
BEGIN
		RAISE NOTICE 'FUN NOW!!!';
END;
$$;
```

2. Make the procedure script executable: `chmod +x make_procedure.sh`
3. Create the migration: `./make_procedure.sh fun.sql`
4. Run the migration: `rails db:migrate`
5. In your database tool of choice (DataGrip, anyone?), run the stored procedure, `CALL fun();`
6. Look for the RAISE NOTICE output
7. `DROP PROCEDURE fun();`

#### FUNCTION

1. Verify the function file looks like `db/functions/whee.sql` :

```
CREATE FUNCTION whee() returns integer  LANGUAGE plpgsql
AS $$
BEGIN
		RETURN 1;
END;
$$;
```

2. Make the function script executable: `chmod +x make_function.sh`
3. Create the migration: `./make_function.sh whee.sql`
4. Run the migration: `rails db:migrate`
5. In your database tool of choice, `SELECT whee();`
6. Make sure you got `1` back?
7. `DROP FUNCTION IF EXISTS whee();`

#### SEEDS

1. Verify the seed file looks like `db/seeds/happies.sql` :

```
INSERT INTO public.happies (id, name, happy_type)
VALUES  (-1, 'At Work', 'professional'),
        (-2, 'At Home', 'personal'),
        (-3, 'At the Park', 'personal'),
        (-4, 'In Bed', 'personal');
```

2. Make the seed script executable: `chmod +x make_seed.sh`
3. Create the migration: `./make_seed.sh happies.sql`
4. Run the migration: `rails db:migrate`
5. In your favorite database tool, `SELECT * FROM happies;`
6. Make sure you get back the 4 rows you inserted

#### VIEW

1. Verify the view file looks like `db/views/vw_happy.sql` :

```
CREATE VIEW vw_happy AS
SELECT * FROM happies where id = -1;;
```

2. Make the view script executable: `chmod +x make_view.sh`
3. Create the migration: `./make_view.sh happy_view.sql`
4. Run the migration: `rails db:migrate`
5. In datagrip, `SELECT * FROM happy_view;`
6. `DROP VIEW IF EXISTS happy_view;`

#### TRIGGER

Note: We have naming conventions to make trigger functions and triggers more findable and self-documenting.

1. Verify you have a trigger function defined in `db/functions/tr_prevent_deletion.sql` that looks like:

```
CREATE OR REPLACE FUNCTION tr_prevent_deletion()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Deletion is not allowed from this table.';
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

2. Create a migration to create this function: `./make_function.sh tr_prevent_deletion.sql`
3. Verify the before delete **trigger** file looks like `db/triggers/trbd_happies.sql`:

```
CREATE TRIGGER trbd_happies
BEFORE DELETE ON happies
FOR EACH ROW
          EXECUTE FUNCTION tr_calculate_entity_contacts;
```

4. Create a migration to create this trigger: `./make_trigger.sh trbd_happies.sql`
5. Run the migrations: `rails db:migrate`
6. In your favorite sql tool, verify the trigger exists
7. activate the trigger with `DELETE from happies WHERE id < 0;

### CLEANUP

```SQL
DROP TRIGGER IF EXISTS trbd_happies ON happies;
DROP FUNCTION IF EXISTS tr_prevent_deletion();
DROP VIEW IF EXISTS vw_happy;
DROP FUNCTION IF EXISTS whee();
DROP PROCEDURE IF EXISTS fun();
DROP TABLE IF EXISTS happies;
```

## GENERAL USAGE NOTE

These shell scripts are written to work in Linux.

- If you're on Windows, they should work in the WSL terminal (Search for "ubuntu" or "WSL" in Start Menu)
- If you're on the Mac, you'll need to edit the `sed` commands to work with `sed` on the Mac, which is different!

## LICENSE

The MIT License (MIT)

Copyright (c) 2025 Gemini Legal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## ACKNOWLEDGEMENTS

- [fx](https://github.com/teoljungberg/fx)
- [Scenic](https://github.com/scenic-views/scenic)
