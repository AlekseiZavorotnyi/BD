DROP FUNCTION IF EXISTS trg_check_hours();

CREATE FUNCTION trg_check_hours()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.hours_worked < 0 THEN
        RAISE EXCEPTION 'Часы не могут быть отрицательными';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
