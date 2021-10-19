/*
 * This script must be treated as a tool to process initial raw data to appropriate state.
 * Actions performed:
 * 	- Changing columns data types to appropriate ones
 * 	- Handling null values
 * 	- Dealing with string artifacts as ""
 * 	- Creating nitial calendar table and filling it with auxiliary date interval (5 years)
 * 
 * All the data in such aquired tebles were exported in sql-insert corresponding files 
 * via DBeaver GUI and will be used in isertion section further.
 */


--CREATE DATABASE property;
--CREATE SCHEMA IF NOT EXISTS rp;

-- Changing rp.user_activity column create_timestamp data type to timestamp
DO $$
BEGIN
  IF (	SELECT c.data_type <> 'timestamp without time zone'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 		AND
				c.table_schema = 'rp' 				AND
				c.table_name = 'user_activity' 		AND
				c.column_name = 'create_timestamp')
  THEN
  		UPDATE rp.user_activity SET create_timestamp = NULL WHERE create_timestamp = '';
      	ALTER TABLE IF EXISTS rp.user_activity ALTER COLUMN create_timestamp TYPE timestamp USING create_timestamp::timestamp;
  END IF;
END $$;

-- Changing rp.user_activity columns item_id, user_id, event_type data type to text
UPDATE rp.user_activity SET item_id = NULL WHERE item_id = '';
ALTER TABLE IF EXISTS rp.user_activity ALTER COLUMN item_id TYPE varchar(36);
UPDATE rp.user_activity SET user_id = NULL WHERE user_id = '';
ALTER TABLE IF EXISTS rp.user_activity ALTER COLUMN user_id TYPE varchar(36);
UPDATE rp.user_activity SET event_type = NULL WHERE event_type = '';
ALTER TABLE IF EXISTS rp.user_activity ALTER COLUMN event_type TYPE TEXT;

-- Adding column for date storage
DO $$
BEGIN
  IF EXISTS (	SELECT *
				FROM information_schema.columns c
				WHERE 	c.table_catalog = 'property' 		AND
						c.table_schema = 'rp' 				AND
						c.table_name = 'user_activity' 		AND
						c.column_name = 'create_timestamp')
  THEN
  		ALTER TABLE IF EXISTS rp.user_activity ADD COLUMN IF NOT EXISTS "date" date;
  		UPDATE rp.user_activity
  		SET "date" = date(create_timestamp);
  END IF;
END $$;

-- Adding column for time storage
DO $$
BEGIN
  IF EXISTS (	SELECT *
				FROM information_schema.columns c
				WHERE 	c.table_catalog = 'property' 		AND
						c.table_schema = 'rp' 				AND
						c.table_name = 'user_activity' 		AND
						c.column_name = 'create_timestamp')
  THEN
  		ALTER TABLE IF EXISTS rp.user_activity ADD COLUMN IF NOT EXISTS "time" time;
  		UPDATE rp.user_activity
  		SET "time" = create_timestamp::time;
  END IF;
END $$;

-- Droping create_timestamp column to prevent normalization violation
ALTER TABLE IF EXISTS rp.user_activity DROP COLUMN IF EXISTS create_timestamp;

-- Changing rp.event_types columns step, meaning, Event type data type to text
ALTER TABLE IF EXISTS rp.event_types ALTER COLUMN step TYPE int2 USING step::int2;
ALTER TABLE IF EXISTS rp.event_types ALTER COLUMN meaning TYPE TEXT;

-- Renaming column Event type to event_type for further usability
DO $$
BEGIN
  IF EXISTS(SELECT *
		    FROM information_schema.COLUMNS c
		    WHERE 	c.table_catalog = 'property' 		AND
					c.table_schema = 'rp' 				AND
					c.table_name = 'event_types' 		AND
					c.column_name = 'Event type')
  THEN
		ALTER TABLE IF EXISTS rp.event_types RENAME COLUMN "Event type" TO event_type;
     	ALTER TABLE IF EXISTS rp.event_types ALTER COLUMN event_type TYPE TEXT;
  END IF;
END $$;


-- Changing rp.property columns data types to appropriate ones
UPDATE rp.property SET item_id = NULL WHERE item_id = '';
ALTER TABLE IF EXISTS rp.property ALTER COLUMN item_id TYPE varchar(36);
UPDATE rp.property SET district_uuid = NULL WHERE district_uuid = '';
ALTER TABLE IF EXISTS rp.property ALTER COLUMN district_uuid TYPE varchar(36);
DO $$
BEGIN
  IF (	SELECT c.data_type <> 'numeric'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 	AND
				c.table_schema = 'rp' 			AND
				c.table_name = 'property' 		AND
				c.column_name = 'deposit')
  THEN
  		UPDATE rp.property SET deposit = NULL WHERE deposit = '';
      	ALTER TABLE IF EXISTS rp.property ALTER COLUMN deposit TYPE NUMERIC(14,2) USING deposit::numeric(14,2);
  END IF;
  IF (	SELECT c.data_type <> 'numeric'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 	AND
				c.table_schema = 'rp' 			AND
				c.table_name = 'property' 		AND
				c.column_name = 'monthly_rent')
  THEN
  		UPDATE rp.property SET monthly_rent = NULL WHERE monthly_rent = '';
		ALTER TABLE IF EXISTS rp.property ALTER COLUMN monthly_rent TYPE NUMERIC(14,2) USING monthly_rent::numeric(14,2);
  END IF;
  IF (	SELECT c.data_type <> 'smallint'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 	AND
				c.table_schema = 'rp' 			AND
				c.table_name = 'property' 		AND
				c.column_name = 'room_qty')
  THEN
  		UPDATE rp.property SET room_qty = NULL WHERE room_qty = '';
		ALTER TABLE IF EXISTS rp.property ALTER COLUMN room_qty TYPE int2 USING room_qty::int2;
  END IF;
  IF (	SELECT c.data_type <> 'numeric'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 	AND
				c.table_schema = 'rp' 			AND
				c.table_name = 'property' 		AND
				c.column_name = 'unit_area')
  THEN
  		UPDATE rp.property SET unit_area = NULL WHERE unit_area = '';
		ALTER TABLE IF EXISTS rp.property ALTER COLUMN unit_area TYPE NUMERIC(5,2) USING unit_area::numeric(5,2);
  END IF;
  IF (	SELECT c.data_type <> 'boolean'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 	AND
				c.table_schema = 'rp' 			AND
				c.table_name = 'property' 		AND
				c.column_name = 'has_elevator')
  THEN
  		UPDATE rp.property SET has_elevator = NULL WHERE has_elevator = '';
		ALTER TABLE IF EXISTS rp.property ALTER COLUMN has_elevator TYPE boolean USING has_elevator::boolean;
  END IF;
  IF (	SELECT c.data_type <> 'smallint'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 	AND
				c.table_schema = 'rp' 			AND
				c.table_name = 'property' 		AND
				c.column_name = 'building_floor_count')
  THEN
  		UPDATE rp.property SET building_floor_count = NULL WHERE building_floor_count = '';
		ALTER TABLE IF EXISTS rp.property ALTER COLUMN building_floor_count TYPE int2 USING building_floor_count::int2;
  END IF;
  IF (	SELECT c.data_type <> 'smallint'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 	AND
				c.table_schema = 'rp' 			AND
				c.table_name = 'property' 		AND
				c.column_name = 'unit_floor')
  THEN
  		UPDATE rp.property SET unit_floor = NULL WHERE unit_floor = '';
		ALTER TABLE IF EXISTS rp.property ALTER COLUMN unit_floor TYPE int2 USING unit_floor::int2;
  END IF;
  IF (	SELECT c.data_type <> 'boolean'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 	AND
				c.table_schema = 'rp' 			AND
				c.table_name = 'property' 		AND
				c.column_name = 'has_storage_area')
  THEN
  		UPDATE rp.property SET has_storage_area = NULL WHERE has_storage_area = '';
		ALTER TABLE IF EXISTS rp.property ALTER COLUMN has_storage_area TYPE boolean USING has_storage_area::boolean;
  END IF;
  IF (	SELECT c.data_type <> 'smallint'
		FROM information_schema.columns c
		WHERE 	c.table_catalog = 'property' 	AND
				c.table_schema = 'rp' 			AND
				c.table_name = 'property' 		AND
				c.column_name = 'property_age')
  THEN
  		UPDATE rp.property SET property_age = NULL WHERE property_age = '';
		ALTER TABLE IF EXISTS rp.property ALTER COLUMN property_age TYPE int2 USING property_age::int2;
  END IF;
END $$;

/*
 * Creating fictional calendar table to fill it with dates for a particular time tracking interval
 */
CREATE TABLE IF NOT EXISTS rp.calendar (
	"date" date PRIMARY KEY
);

-- Fill calendar table with dates
DO $$
DECLARE
/*
 * specify start date and tracking interval for calendar table
 */
	start_date date := '2019-01-01';
	tracking_interval_years int2 := 5;
BEGIN
TRUNCATE rp.calendar;
INSERT INTO rp.calendar
SELECT i::date
FROM generate_series(start_date, start_date + INTERVAL '1 year'*tracking_interval_years, INTERVAL '1 day') i;
END $$;