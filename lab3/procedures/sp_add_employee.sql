DROP PROCEDURE IF EXISTS sp_add_employee;

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
