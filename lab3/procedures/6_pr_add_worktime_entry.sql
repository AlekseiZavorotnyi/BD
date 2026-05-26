DROP PROCEDURE IF EXISTS pr_add_worktime_entry;

CREATE PROCEDURE pr_add_worktime_entry(
    emp_id INT,
    work_date DATE,
    hours DECIMAL
)
    LANGUAGE plpgsql
AS $$
BEGIN
    IF hours < 0 OR hours > 24 THEN
        RAISE EXCEPTION 'Количество часов должно быть от 0 до 24';
END IF;

    IF NOT EXISTS (SELECT 1 FROM "Employee" WHERE employee_id = emp_id) THEN
        RAISE EXCEPTION 'Сотрудник % не найден', emp_id;
END IF;

INSERT INTO "WorkTime"(worktime_id, employee_id, work_date, hours_worked)
VALUES (
           (SELECT COALESCE(MAX(worktime_id), 0) + 1 FROM "WorkTime"),
           emp_id,
           work_date,
           hours
       );
END;
$$;
