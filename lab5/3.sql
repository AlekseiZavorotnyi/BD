-- СЦЕНАРИЙ 3. Изменение зарплаты и параллельные транзакции


-- Успешная транзакция с фиксацией изменений
-- Меняем зарплату сотруднику 40.

BEGIN;

UPDATE Dogovors
SET salary = salary + 5000
WHERE employee_id = 40;

COMMIT;

SELECT employee_id, position, salary
FROM Dogovors
WHERE employee_id = 40;



-- Пытаемся обновить договор(делим зарплату на 0).

BEGIN;

-- Ошибка
UPDATE Dogovors
SET salary = salary / 0
WHERE employee_id = 40;

ROLLBACK;

SELECT employee_id, position, salary
FROM Dogovors
WHERE employee_id = 40;



-- SAVEPOINT и частичный откат

BEGIN;

UPDATE Dogovors
SET salary = salary + 3000
WHERE employee_id = 40;

SAVEPOINT before_bad_change;

UPDATE Dogovors
SET salary = -1000
WHERE employee_id = 40;

ROLLBACK TO SAVEPOINT before_bad_change;

UPDATE Dogovors
SET salary = salary + 2000
WHERE employee_id = 40;

COMMIT;

SELECT employee_id, position, salary
FROM Dogovors
WHERE employee_id = 40;



-- Блокировка строки одной транзакцией другой

-- СЕССИЯ 1
BEGIN;

UPDATE Dogovors
SET salary = salary + 10000
WHERE employee_id = 50;


-- СЕССИЯ 2
BEGIN;

UPDATE Dogovors
SET salary = salary - 5000
WHERE employee_id = 50;   -- будет ждать, пока СЕССИЯ 1 не завершит транзакцию

-- После COMMIT в СЕССИИ 1 это UPDATE выполнится.
-- Затем:

COMMIT;

SELECT employee_id, salary
FROM Dogovors
WHERE employee_id = 50;



-- READ COMMITTED — видит уже зафиксированные изменения

-- СЕССИЯ 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT salary
FROM Dogovors
WHERE employee_id = 60;

UPDATE Dogovors
SET salary = salary + 5000
WHERE employee_id = 60;


-- СЕССИЯ 2
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT salary
FROM Dogovors
WHERE employee_id = 60;   -- увидит старое значение (100000), пока СЕССИЯ 1 не закоммитила

-- Теперь СЕССИЯ 1 делает COMMIT:

-- СЕССИЯ 1
COMMIT;

-- СЕССИЯ 2 снова читает:
SELECT salary
FROM Dogovors
WHERE employee_id = 60;   -- теперь увидит новое значение (105000)

COMMIT;



-- REPEATABLE READ — фиксированный снимок в рамках транзакции

-- СЕССИЯ 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT salary
FROM Dogovors
WHERE employee_id = 70;   -- допустим, 90000


-- СЕССИЯ 2
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE Dogovors
SET salary = salary + 10000
WHERE employee_id = 70;

COMMIT;


-- СЕССИЯ 1
SELECT salary
FROM Dogovors
WHERE employee_id = 70;   -- всё ещё 90000

COMMIT;

-- Проверка итогового значения:
SELECT salary
FROM Dogovors
WHERE employee_id = 70;   -- уже 100000



-- SERIALIZABLE — конфликт при параллельном обновлении

-- СЕССИЯ 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT salary
FROM Dogovors
WHERE employee_id = 80;   -- допустим, 100000

UPDATE Dogovors
SET salary = salary + 5000
WHERE employee_id = 80;


-- СЕССИЯ 2
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT salary
FROM Dogovors
WHERE employee_id = 80;   -- тоже видит 100000 (свой снимок)

UPDATE Dogovors
SET salary = salary - 3000
WHERE employee_id = 80;


-- Теперь СЕССИЯ 1 делает COMMIT:

COMMIT;  -- СЕССИЯ 1


-- СЕССИЯ 2 пытается закоммитить:

COMMIT;  -- ошибка:
-- ERROR: could not serialize access due to concurrent update

-- После ошибки нужно сделать ROLLBACK в СЕССИИ 2:

ROLLBACK;


-- Итоговое значение:
SELECT salary
FROM Dogovors
WHERE employee_id = 80;
