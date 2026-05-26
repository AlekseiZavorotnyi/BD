--СЦЕНАРИЙ 1. Приём нового сотрудника и создание договора
--Успешная транзакция
BEGIN;

INSERT INTO Employee (employee_id, first_name, last_name, birth_date)
VALUES (2001, 'Иван', 'Новиков', '1990-05-10');

INSERT INTO Dogovors (dogovor_id, position, start_date, salary, department, employee_id)
VALUES (5001, 'Инженер', CURRENT_DATE, 120000, 'R&D', 2001);

COMMIT;

SELECT e.employee_id, e.first_name, e.last_name, d.position, d.salary, d.department
FROM Employee e
         LEFT JOIN Dogovors d ON d.employee_id = e.employee_id
WHERE e.employee_id = 3001;

--Ошибка (дубликат PK) и полный откат
BEGIN;

INSERT INTO Employee (employee_id, first_name, last_name, birth_date)
VALUES (3002, 'Павел', 'Сидоров', '1988-03-12');

INSERT INTO Dogovors (dogovor_id, position, start_date, salary, department, employee_id)
VALUES (7001, 'Менеджер', CURRENT_DATE, 90000, 'Sales', 3002); -- конфликт PK

ROLLBACK;

SELECT *
FROM Employee
WHERE employee_id = 3002;

--SAVEPOINT — сотрудник остаётся, договор исправляется
BEGIN;

INSERT INTO Employee (employee_id, first_name, last_name, birth_date)
VALUES (3003, 'Анна', 'Крылова', '1995-07-21');

SAVEPOINT before_bad_contract;

INSERT INTO Dogovors (dogovor_id, position, start_date, salary, department, employee_id)
VALUES (7001, 'Аналитик', CURRENT_DATE, -50000, 'BI', 3003); -- ошибка логики

ROLLBACK TO SAVEPOINT before_bad_contract;

INSERT INTO Dogovors (dogovor_id, position, start_date, salary, department, employee_id)
VALUES (7002, 'Аналитик', CURRENT_DATE, 110000, 'BI', 3003);

COMMIT;

SELECT e.employee_id, e.first_name, d.position, d.salary
FROM Employee e
         LEFT JOIN Dogovors d ON d.employee_id = e.employee_id
WHERE e.employee_id = 3003;


--СЦЕНАРИЙ 2. Оформление отпуска сотрудника
--Успешная транзакция
BEGIN;

INSERT INTO Vacation (vacation_id, employee_id, start_date, end_date, type)
VALUES (8001, 10, '2024-06-01', '2024-06-10', 'paid');

UPDATE WorkTime
SET hours_worked = 0
WHERE employee_id = 10
  AND work_date BETWEEN '2024-06-01' AND '2024-06-10';

COMMIT;

SELECT v.vacation_id, v.start_date, v.end_date, w.work_date, w.hours_worked
FROM Vacation v
         LEFT JOIN WorkTime w ON w.employee_id = v.employee_id
WHERE v.vacation_id = 8001;
--Ошибка (несуществующий employee_id), полный откат
BEGIN;

INSERT INTO Vacation (vacation_id, employee_id, start_date, end_date, type)
VALUES (8002, 9999, '2024-07-01', '2024-07-05', 'paid'); -- сотрудника нет

UPDATE WorkTime
SET hours_worked = 0
WHERE employee_id = 9999;

ROLLBACK;

SELECT *
FROM Vacation
WHERE vacation_id = 8002;

--SAVEPOINT — отпуск остаётся, неверное обновление WorkTime откатывается
BEGIN;

INSERT INTO Vacation (vacation_id, employee_id, start_date, end_date, type)
VALUES (8003, 15, '2024-08-01', '2024-08-05', 'paid');

SAVEPOINT before_bad_update;

UPDATE WorkTime
SET hours_worked = -10   -- ошибка логики
WHERE employee_id = 15;

ROLLBACK TO SAVEPOINT before_bad_update;

UPDATE WorkTime
SET hours_worked = 0
WHERE employee_id = 15
  AND work_date BETWEEN '2024-08-01' AND '2024-08-05';

COMMIT;

SELECT v.vacation_id, v.start_date, v.end_date, w.work_date, w.hours_worked
FROM Vacation v
         LEFT JOIN WorkTime w ON w.employee_id = v.employee_id
WHERE v.vacation_id = 8003;
