DROP FUNCTION IF EXISTS fn_get_employee_age(INT);
DROP FUNCTION IF EXISTS fn_get_total_hours(INT);
DROP FUNCTION IF EXISTS fn_check_vacation_overlap(INT, DATE, DATE);
DROP PROCEDURE IF EXISTS sp_add_employee;
DROP PROCEDURE IF EXISTS sp_add_worktime;
DROP PROCEDURE IF EXISTS sp_add_vacation;
DROP FUNCTION IF EXISTS trg_check_hours();
DROP FUNCTION IF EXISTS trg_log_employee();
DROP FUNCTION IF EXISTS trg_check_vacation();
DROP TRIGGER IF EXISTS trg_prevent_negative_hours ON WorkTime;
DROP TRIGGER IF EXISTS trg_log_employee_changes ON Employee;
DROP TRIGGER IF EXISTS trg_prevent_vacation_overlap ON Vacation;
DROP TABLE IF EXISTS EmployeeLog CASCADE;

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

CREATE PROCEDURE sp_add_employee(
    p_id INT,
    p_first VARCHAR,
    p_last VARCHAR,
    p_birth DATE,
    p_hire DATE,
    p_dep INT,
    p_pos INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Employee(employee_id, first_name, last_name, birth_date, hire_date, department_id, position_id)
    VALUES (p_id, p_first, p_last, p_birth, p_hire, p_dep, p_pos);
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Ошибка: указан неверный отдел или должность';
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ошибка: сотрудник с id % уже существует', p_id;
END;
$$;

CREATE PROCEDURE sp_add_worktime(
    p_id INT,
    p_emp INT,
    p_date DATE,
    p_hours DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO WorkTime(worktime_id, employee_id, work_date, hours_worked)
    VALUES (p_id, p_emp, p_date, p_hours);
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Ошибка: сотрудник % не существует', p_emp;
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ошибка: запись рабочего времени с id % уже существует', p_id;
END;
$$;

CREATE PROCEDURE sp_add_vacation(
    p_id INT,
    p_emp INT,
    p_start DATE,
    p_end DATE,
    p_type VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF fn_check_vacation_overlap(p_emp, p_start, p_end) THEN
        RAISE EXCEPTION 'Ошибка: отпуск пересекается с существующим';
    END IF;

    INSERT INTO Vacation(vacation_id, employee_id, start_date, end_date, type)
    VALUES (p_id, p_emp, p_start, p_end, p_type);
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Ошибка: сотрудник % не существует', p_emp;
END;
$$;

CREATE TABLE EmployeeLog (
    log_id SERIAL PRIMARY KEY,
    employee_id INT,
    action VARCHAR(20),
    changed_at TIMESTAMP DEFAULT NOW()
);

CREATE FUNCTION trg_check_hours()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.hours_worked < 0 THEN
        RAISE EXCEPTION 'Часы не могут быть отрицательными';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_negative_hours
BEFORE INSERT OR UPDATE ON WorkTime
FOR EACH ROW
EXECUTE FUNCTION trg_check_hours();

CREATE FUNCTION trg_log_employee()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO EmployeeLog(employee_id, action)
    VALUES (NEW.employee_id, TG_OP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_employee_changes
AFTER INSERT OR UPDATE ON Employee
FOR EACH ROW
EXECUTE FUNCTION trg_log_employee();

CREATE FUNCTION trg_check_vacation()
RETURNS TRIGGER AS $$
BEGIN
    IF fn_check_vacation_overlap(NEW.employee_id, NEW.start_date, NEW.end_date) THEN
        RAISE EXCEPTION 'Отпуск пересекается с существующим';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_vacation_overlap
BEFORE INSERT OR UPDATE ON Vacation
FOR EACH ROW
EXECUTE FUNCTION trg_check_vacation();
