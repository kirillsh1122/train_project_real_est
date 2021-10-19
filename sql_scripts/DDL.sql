-- DDL script to create all DB objects

--CREATE DATABASE property;

-- STAR SCHEMA

CREATE SCHEMA IF NOT EXISTS rp;

-- drop tables after initial processing script
DROP TABLE IF EXISTS rp.event_types CASCADE;
DROP TABLE IF EXISTS rp.property CASCADE;
DROP TABLE IF EXISTS rp.calendar CASCADE;
DROP TABLE IF EXISTS rp.user_activity CASCADE;

CREATE TABLE IF NOT EXISTS rp.event_types (
/*
 * Dimension table
 * Table contains description for users activity
 */
	step serial NOT NULL,			-- EVENT TYPE ID
	event_type text PRIMARY KEY,	-- event TYPE name
	meaning text NULL DEFAULT NULL	-- EVENT description
);

CREATE TABLE IF NOT EXISTS rp.property (
/*
 * Dimension table
 * Table contains various information about property units in DB
 */
	item_id varchar(36) PRIMARY KEY,				-- item ID
	deposit numeric(14,2) NULL DEFAULT NULL,		-- deposit amount. NULLS allowed IN CASE OF uncertainty OR depositless positions
	monthly_rent numeric(14,2) NULL DEFAULT NULL,	-- monthly rent amount. NULLS allowed IN CASE OF uncertainty
	district_uuid varchar(36) NULL DEFAULT NULL,	-- district id TO identify district FOR certain POSITION. NULLS allowed IN CASE OF uncertainty
	room_qty int2 NULL DEFAULT NULL,				-- room quantity FOR POSITION. NULLS allowed IN CASE OF obscurity
	unit_area numeric(5,2) NULL DEFAULT NULL,		-- unit area. NULLS allowed IN CASE OF obscurity
	has_elevator bool NULL DEFAULT NULL,			-- Does unit have an elevator. NULLS allowed IN CASE OF obscurity
	building_floor_count int2 NULL DEFAULT NULL,	-- Floors quantity IN unit building. NULLS allowed IN CASE OF obscurity
	unit_floor int2 NULL DEFAULT NULL,				-- Floor unit IS located AT. NULLS allowed IN CASE OF obscurity
	has_storage_area bool NULL DEFAULT NULL,		-- Does unit have a storage area. NULLS allowed IN CASE OF obscurity
	property_age int2 NULL DEFAULT NULL				-- Units building age. NULLS allowed IN CASE OF obscurity
);


-- Creating immutable functions which will be used in generated columns in calendar table

-- get day name
CREATE OR REPLACE FUNCTION rp.get_day_name(var_date date) RETURNS varchar(9)
LANGUAGE sql IMMUTABLE
AS $$
SELECT to_char(var_date, 'day')
$$;

-- get day number in week
CREATE OR REPLACE FUNCTION rp.get_day_number_in_week(var_date date) RETURNS int2
LANGUAGE sql IMMUTABLE
AS $$
SELECT EXTRACT(dow FROM var_date)
$$;

-- get day number in month
CREATE OR REPLACE FUNCTION rp.get_day_number_in_month(var_date date) RETURNS int2
LANGUAGE sql IMMUTABLE
AS $$
SELECT EXTRACT(DAY FROM var_date)
$$;

-- get week number in year
CREATE OR REPLACE FUNCTION rp.get_calendar_week_number(var_date date) RETURNS int2
LANGUAGE sql IMMUTABLE
AS $$
SELECT EXTRACT(WEEK FROM var_date)
$$;

-- get week start day
CREATE OR REPLACE FUNCTION rp.get_week_start_day(var_date date) RETURNS date
LANGUAGE sql IMMUTABLE
AS $$
SELECT date_trunc('week', var_date)::date
$$;

-- get week end day
CREATE OR REPLACE FUNCTION rp.get_week_end_day(var_date date) RETURNS date
LANGUAGE sql IMMUTABLE
AS $$
SELECT (date_trunc('week', var_date)+ '6 days'::interval)::date
$$;

-- get calendar month number
CREATE OR REPLACE FUNCTION rp.get_calendar_month_number(var_date date) RETURNS int2
LANGUAGE sql IMMUTABLE
AS $$
SELECT EXTRACT(MONTH FROM var_date)
$$;

-- get days in calendar month
CREATE OR REPLACE FUNCTION rp.get_days_in_cal_month(var_date date) RETURNS int2
LANGUAGE sql IMMUTABLE
AS $$
SELECT DATE_PART('days', DATE_TRUNC('month', var_date) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL)
$$;

-- get start day of calendar month
CREATE OR REPLACE FUNCTION rp.get_start_of_cal_month(var_date date) RETURNS date
LANGUAGE sql IMMUTABLE
AS $$
SELECT date_trunc('month', var_date)::date
$$;

-- get end day of calendar month
CREATE OR REPLACE FUNCTION rp.get_end_of_cal_month(var_date date) RETURNS date
LANGUAGE sql IMMUTABLE
AS $$
SELECT (date_trunc('month', var_date) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL)::date
$$;

-- get calendar month name
CREATE OR REPLACE FUNCTION rp.get_calendar_month_name(var_date date) RETURNS varchar(9)
LANGUAGE sql IMMUTABLE
AS $$
SELECT to_char(var_date, 'month')
$$;

-- get year calendar quarter
CREATE OR REPLACE FUNCTION rp.get_calendar_quarter(var_date date) RETURNS varchar(7)
LANGUAGE sql IMMUTABLE
AS $$
SELECT to_char(DATE_TRUNC('quarter', var_date),'yyyy-0q')
$$;

-- get quarter number
CREATE OR REPLACE FUNCTION rp.get_calendar_quarter_number(var_date date) RETURNS int2
LANGUAGE sql IMMUTABLE
AS $$
SELECT EXTRACT(quarter FROM var_date)
$$;

-- get days quantity in quarter
CREATE OR REPLACE FUNCTION rp.get_days_in_cal_quarter(var_date date) RETURNS int2
LANGUAGE sql IMMUTABLE
AS $$
SELECT EXTRACT(epoch FROM DATE_TRUNC('quarter', var_date) + 3*INTERVAL '1 month' - DATE_TRUNC('quarter', var_date))/(3600*24)
$$;

-- get calendar quarter start date
CREATE OR REPLACE FUNCTION rp.get_start_of_cal_quarter(var_date date) RETURNS date
LANGUAGE sql IMMUTABLE
AS $$
SELECT DATE_TRUNC('quarter', var_date)
$$;

-- get calendar quarter end date
CREATE OR REPLACE FUNCTION rp.get_end_of_cal_quarter(var_date date) RETURNS date
LANGUAGE sql IMMUTABLE
AS $$
SELECT DATE_TRUNC('quarter', var_date) + 3*INTERVAL '1 month' - INTERVAL '1 day'
$$;

-- get calendar year
CREATE OR REPLACE FUNCTION rp.get_calendar_year(var_date date) RETURNS int2
LANGUAGE sql IMMUTABLE
AS $$
SELECT EXTRACT(YEAR FROM var_date)
$$;

-- get calendar year days
CREATE OR REPLACE FUNCTION rp.get_days_in_cal_year(var_date date) RETURNS int2
LANGUAGE sql IMMUTABLE
AS $$
SELECT EXTRACT(epoch FROM DATE_TRUNC('year', var_date) + '1 year'::INTERVAL - '1 DAY'::INTERVAL - DATE_TRUNC('year', var_date))/(3600*24)
$$;

-- get calendar year start date
CREATE OR REPLACE FUNCTION rp.get_start_of_cal_year(var_date date) RETURNS date
LANGUAGE sql IMMUTABLE
AS $$
SELECT DATE_TRUNC('year', var_date)
$$;

-- get calendar year end date
CREATE OR REPLACE FUNCTION rp.get_end_of_cal_year(var_date date) RETURNS date
LANGUAGE sql IMMUTABLE
AS $$
SELECT DATE_TRUNC('year', var_date) + '1 year'::INTERVAL - '1 DAY'::INTERVAL
$$;

CREATE TABLE IF NOT EXISTS rp.calendar (
/*
 * Dimension table
 * Table performs itself a calendar with various additional information for each particular date it contains
 */
	"date" date PRIMARY KEY,
	day_name varchar(9) NOT NULL GENERATED ALWAYS AS (rp.get_day_name(date)) STORED,
	day_number_in_week int2 NOT NULL GENERATED ALWAYS AS (rp.get_day_number_in_week(date)) STORED,
	day_number_in_month int2 NOT NULL GENERATED ALWAYS AS (rp.get_day_number_in_month(date)) STORED,
	calendar_week_number int2 NOT NULL GENERATED ALWAYS AS (date_part('week'::text, date)) STORED,
	week_start_day date NOT NULL GENERATED ALWAYS AS (rp.get_week_start_day(date)) STORED,
	week_end_day date NOT NULL GENERATED ALWAYS AS (rp.get_week_end_day(date)) STORED,
	calendar_month_number int2 NOT NULL GENERATED ALWAYS AS (rp.get_calendar_month_number(date)) STORED,
	days_in_cal_month int2 NOT NULL GENERATED ALWAYS AS (rp.get_days_in_cal_month(date)) STORED,
	start_of_cal_month date NOT NULL GENERATED ALWAYS AS (rp.get_start_of_cal_month(date)) STORED,
	end_of_cal_month date NOT NULL GENERATED ALWAYS AS (rp.get_end_of_cal_month(date)) STORED,
	calendar_month_name varchar(9) NOT NULL GENERATED ALWAYS AS (rp.get_calendar_month_name(date)) STORED,
	calendar_quarter varchar(7) NOT NULL GENERATED ALWAYS AS (rp.get_calendar_quarter(date)) STORED,
	calendar_quarter_number int2 NOT NULL GENERATED ALWAYS AS (rp.get_calendar_quarter_number(date)) STORED,
	days_in_cal_quarter int2 NOT NULL GENERATED ALWAYS AS (rp.get_days_in_cal_quarter(date)) STORED,
	start_of_cal_quarter date NOT NULL GENERATED ALWAYS AS (rp.get_start_of_cal_quarter(date)) STORED,
	end_of_cal_quarter date NOT NULL GENERATED ALWAYS AS (rp.get_end_of_cal_quarter(date)) STORED,
	calendar_year int2 NOT NULL GENERATED ALWAYS AS (rp.get_calendar_year(date)) STORED,
	days_in_cal_year int2 NOT NULL GENERATED ALWAYS AS (rp.get_days_in_cal_year(date)) STORED,
	start_of_cal_year date NOT NULL GENERATED ALWAYS AS (rp.get_start_of_cal_year(date)) STORED,
	end_of_cal_year date NOT NULL GENERATED ALWAYS AS (rp.get_end_of_cal_year(date)) STORED
);

CREATE TABLE IF NOT EXISTS rp.user_activity (
/*
 * Fact table
 * Table performs itself log-table which track all user activity and uses corresponding dimension tables
 */
	item_id varchar(36) NOT NULL,			-- Unit USER interacted with
	user_id varchar(36) NOT NULL,			-- USER whose activity was tracked
	event_type text NOT NULL,				-- TYPE OF USERs activity
	"date" date NOT NULL,					-- date activity was performed
	"time" time NOT NULL,					-- time activity was performed
	CONSTRAINT fk_user_activity_property_item_id FOREIGN KEY (item_id) REFERENCES rp.property(item_id),
	CONSTRAINT fk_user_activity_event_types_event_type FOREIGN KEY (event_type) REFERENCES rp.event_types(event_type),
	CONSTRAINT fk_user_activity_calendar_date FOREIGN KEY ("date") REFERENCES rp.calendar("date"),
	-- Creating compound primary key so each record in fact table must be unique
	CONSTRAINT pk_user_activity_compound PRIMARY KEY (item_id, user_id, event_type, "date", "time")
);




