DROP PROCEDURE IF EXISTS pr_update_salary;

CREATE PROCEDURE pr_update_salary(
    emp_id INT,
    amount DECIMAL
)
    LANGUAGE plpgsql
AS $$
BEGIN
    IF amount = 0 THEN
        RAISE EXCEPTION 'Сумма изменения зарплаты не может быть нулевой';
END IF;

UPDATE "Dogovors"
SET salary = salary + amount
WHERE employee_id = emp_id;

IF NOT FOUND THEN
        RAISE EXCEPTION 'Договор сотрудника % не найден', emp_id;
END IF;
END;
$$;
