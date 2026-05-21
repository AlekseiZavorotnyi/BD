BEGIN;

INSERT INTO Employee (employee_id, first_name, last_name, birth_date)
VALUES (2001, 'Иван', 'Новиков', '1990-05-10');

INSERT INTO Dogovors (dogovor_id, position, start_date, salary, department, employee_id)
VALUES (5001, 'Инженер', CURRENT_DATE, 120000, 'R&D', 2001);

COMMIT;
