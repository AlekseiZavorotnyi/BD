DROP FUNCTION IF EXISTS fn_get_total_hours(INT);

CREATE FUNCTION fn_get_total_hours(emp_id INT)
RETURNS DECIMAL AS $$
DECLARE
    total DECIMAL;
BEGIN
    SELECT SUM(hours_worked)
    INTO total
    FROM WorkTime
    WHERE employee_id = emp_id;

    RETURN COALESCE(total, 0);
END;
$$ LANGUAGE plpgsql;
