DROP FUNCTION IF EXISTS fn_check_vacation_overlap(INT, DATE, DATE);

CREATE FUNCTION fn_check_vacation_overlap(emp_id INT, start_d DATE, end_d DATE)
RETURNS BOOLEAN AS $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*)
    INTO cnt
    FROM Vacation
    WHERE employee_id = emp_id
      AND daterange(start_date, end_date, '[]') &&
          daterange(start_d, end_d, '[]');

    RETURN cnt > 0;
END;
$$ LANGUAGE plpgsql;
