CREATE OR REPLACE VIEW user_activity_full AS (
SELECT 	ua.item_id,
		ua.user_id,
		et.*,
		c.*,
		p.deposit,
		p.monthly_rent,
		p.district_uuid,
		p.room_qty,
		p.unit_area,
		p.has_elevator,
		p.building_floor_count,
		p.unit_floor,
		p.has_storage_area,
		p.property_age
FROM rp.user_activity ua 
LEFT JOIN rp.calendar c ON ua."date" = c."date" 
LEFT JOIN rp.property p ON ua.item_id = p.item_id
LEFT JOIN rp.event_types et ON ua.event_type = et.event_type
);