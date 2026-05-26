DROP PROCEDURE IF EXISTS sp_add_vacation;

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
