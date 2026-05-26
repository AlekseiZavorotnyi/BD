DROP FUNCTION IF EXISTS fn_get_employee_age(INT);

CREATE FUNCTION fn_get_employee_age(emp_id INT)
RETURNS INT AS $$
DECLARE
    age_years INT;
BEGIN
    SELECT EXTRACT(YEAR FROM AGE(NOW(), birth_date))
    INTO age_years
    FROM Employee
    WHERE employee_id = emp_id;

    IF age_years IS NULL THEN
        RAISE EXCEPTION 'Сотрудник с id % не найден', emp_id;
    END IF;

    RETURN age_years;
END;
$$ LANGUAGE plpgsql;
