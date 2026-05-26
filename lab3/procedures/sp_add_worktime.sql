DROP PROCEDURE IF EXISTS sp_add_worktime;

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
