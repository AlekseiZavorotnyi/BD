генерация
TRUNCATE TABLE Employee RESTART IDENTITY CASCADE;

INSERT INTO Employee (employee_id, first_name, last_name, birth_date)
SELECT 
    g AS employee_id,
    'Имя' || g,
    'Фамилия' || g,
    DATE '1970-01-01' + (g % 15000)
FROM generate_series(1, 1000) AS g;

TRUNCATE TABLE WorkTime RESTART IDENTITY CASCADE;

INSERT INTO WorkTime (worktime_id, employee_id, work_date, hours_worked)
SELECT
    g AS worktime_id,
    (g % 1000) + 1 AS employee_id,
    DATE '2020-01-01' + (g % 1500),
    (random() * 10)::numeric(4,2)
FROM generate_series(1, 1000000) AS g;


----------------- Первый сценарий----------------------------


Первый сценарий - сложный фильтр по нескольким полям.
Задача - Найти все записи рабочего времени сотрудника за диапазон времени где он работал больше 7 часов.


Тестовый запрос:

EXPLAIN ANALYZE
SELECT *
FROM WorkTime
WHERE employee_id = 500
  AND work_date BETWEEN '2022-01-01' AND '2022-12-31'
  AND hours_worked > 7;


Результат:
Gather  (cost=1000.00..15710.43 rows=71 width=18) (actual time=21.939..101.211 rows=98 loops=1)
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Parallel Seq Scan on worktime  (cost=0.00..14703.33 rows=30 width=18) (actual time=1.371..50.715 rows=33 loops=3)"
"        Filter: ((work_date >= '2022-01-01'::date) AND (work_date <= '2022-12-31'::date) AND (hours_worked > '7'::numeric) AND (employee_id = 500))"
"        Rows Removed by Filter: 333301"
"Planning Time: 1.987 ms"
"Execution Time: 101.994 ms"

Гипотеза:

Применяю:
CREATE INDEX idx_worktime_emp_date_hours
ON WorkTime (employee_id, work_date, hours_worked);

Теперь результат сложного запроска такой:
"Bitmap Heap Scan on worktime  (cost=8.01..270.95 rows=71 width=18) (actual time=0.108..0.245 rows=98 loops=1)"
"  Recheck Cond: ((employee_id = 500) AND (work_date >= '2022-01-01'::date) AND (work_date <= '2022-12-31'::date) AND (hours_worked > '7'::numeric))"
"  Heap Blocks: exact=98"
"  ->  Bitmap Index Scan on idx_worktime_emp_date_hours  (cost=0.00..8.00 rows=71 width=0) (actual time=0.090..0.091 rows=98 loops=1)"
"        Index Cond: ((employee_id = 500) AND (work_date >= '2022-01-01'::date) AND (work_date <= '2022-12-31'::date) AND (hours_worked > '7'::numeric))"
"Planning Time: 0.316 ms"
"Execution Time: 11.002 ms"

Как видно, по результату выполнения EXPLAIN ANALYZE, время выполнения ускорилось в 9 раз.


----------------- Второй сценарий----------------------------

Второй сценарий - сортировка с ограничением.
Задача - Найти 100 последних рабочих записей по дате.


Тестовый запрос:

EXPLAIN ANALYZE
SELECT *
FROM WorkTime
ORDER BY work_date DESC
LIMIT 100;

Результат:
"Limit  (cost=27461.40..27473.07 rows=100 width=18) (actual time=97.743..147.786 rows=100 loops=1)"
"  ->  Gather Merge  (cost=27461.40..124690.49 rows=833334 width=18) (actual time=97.741..147.761 rows=100 loops=1)"
"        Workers Planned: 2"
"        Workers Launched: 2"
"        ->  Sort  (cost=26461.38..27503.05 rows=416667 width=18) (actual time=73.969..73.976 rows=100 loops=3)"
"              Sort Key: work_date DESC"
"              Sort Method: top-N heapsort  Memory: 39kB"
"              Worker 0:  Sort Method: top-N heapsort  Memory: 39kB"
"              Worker 1:  Sort Method: top-N heapsort  Memory: 39kB"
"              ->  Parallel Seq Scan on worktime  (cost=0.00..10536.67 rows=416667 width=18) (actual time=0.022..37.244 rows=333333 loops=3)"
"Planning Time: 11.242 ms"
"Execution Time: 98.875 ms"

Гипотеза:

Применяю:
CREATE INDEX idx_worktime_date_desc
ON WorkTime (work_date DESC);


По итогам повторного анализа получаем такой результат:

"Limit  (cost=0.42..4.84 rows=100 width=18) (actual time=0.019..0.128 rows=100 loops=1)"
"  ->  Index Scan using idx_worktime_date_desc on worktime  (cost=0.42..44108.42 rows=1000000 width=18) (actual time=0.018..0.119 rows=100 loops=1)"
"Planning Time: 0.215 ms"
"Execution Time: 0.143 ms"

Таким образом, время выполнения скрипта уменьшилось в 146 раз! 


----------------- Третий сценарий----------------------------

Сравнение двух вариантов индексирования
Задача - Найти все записи рабочего времени за конкретную дату.

Запрос:

    EXPLAIN ANALYZE
    SELECT
    worktime_id,
    employee_id,
    work_date,
    hours_worked
    FROM WorkTime
    WHERE work_date = '2023-05-10';


Результат без индексирования:

"Gather  (cost=1000.00..12644.63 rows=663 width=18) (actual time=100.637..2019.251 rows=666 loops=1)"
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Parallel Seq Scan on worktime  (cost=0.00..11578.33 rows=276 width=18) (actual time=3.593..1868.168 rows=222 loops=3)"
"        Filter: (work_date = '2023-05-10'::date)"
"        Rows Removed by Filter: 333111"
"Planning Time: 12.170 ms"
"Execution Time: 2019.752 ms"

Гипотеза:
Индекс по work_date должен ускорить поиск. B‑Tree будет быстрее, но BRIN займёт меньше места и тоже даст ускорение.

Добавим индекс:
CREATE INDEX idx_worktime_date_btree
ON WorkTime (work_date);


Результат после добавления индекса:

"Bitmap Heap Scan on worktime  (cost=9.56..1946.06 rows=663 width=18) (actual time=0.768..15.652 rows=666 loops=1)"
"  Recheck Cond: (work_date = '2023-05-10'::date)"
"  Heap Blocks: exact=666"
"  ->  Bitmap Index Scan on idx_worktime_date_btree  (cost=0.00..9.40 rows=663 width=0) (actual time=0.295..0.296 rows=666 loops=1)"
"        Index Cond: (work_date = '2023-05-10'::date)"
"Planning Time: 1.011 ms"
"Execution Time: 17.886 ms"



Теперь добавим индекс:
CREATE INDEX idx_worktime_date_brin
ON WorkTime USING BRIN (work_date);


"Gather  (cost=1000.00..12644.63 rows=663 width=18) (actual time=0.955..109.400 rows=666 loops=1)"
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Parallel Seq Scan on worktime  (cost=0.00..11578.33 rows=276 width=18) (actual time=0.671..91.564 rows=222 loops=3)"
"        Filter: (work_date = '2023-05-10'::date)"
"        Rows Removed by Filter: 333111"
"Planning Time: 0.128 ms"
"Execution Time: 109.546 ms"




----------------- Четвертый сценарий----------------------------

4.1

Задача - Найти записи WorkTime, где дата начинается с '2023-05'.
Запрос для анализа:

EXPLAIN ANALYZE
SELECT worktime_id, employee_id, work_date, hours_worked
FROM WorkTime
WHERE work_date_str LIKE '2023-05%'
ORDER BY work_date
LIMIT 100;



Результат без индексов:

"Limit  (cost=20250.53..20262.19 rows=100 width=18) (actual time=134.968..139.260 rows=100 loops=1)"
"  ->  Gather Merge  (cost=20250.53..22199.23 rows=16702 width=18) (actual time=134.965..139.249 rows=100 loops=1)"
"        Workers Planned: 2"
"        Workers Launched: 2"
"        ->  Sort  (cost=19250.50..19271.38 rows=8351 width=18) (actual time=120.970..120.977 rows=100 loops=3)"
"              Sort Key: work_date"
"              Sort Method: top-N heapsort  Memory: 36kB"
"              Worker 0:  Sort Method: top-N heapsort  Memory: 36kB"
"              Worker 1:  Sort Method: top-N heapsort  Memory: 36kB"
"              ->  Parallel Seq Scan on worktime  (cost=0.00..18931.33 rows=8351 width=18) (actual time=8.308..117.533 rows=6882 loops=3)"
"                    Filter: (work_date_str ~~ '2023-05%'::text)"
"                    Rows Removed by Filter: 326451"
"Planning Time: 0.311 ms"
"Execution Time: 139.344 ms"



Гипотеза:

Добавим индекс:

CREATE INDEX idx_worktime_date_pattern
ON WorkTime (work_date_str text_pattern_ops);


Результат после добавления индекса:

"Limit  (cost=15708.91..15709.16 rows=100 width=18) (actual time=19.824..19.847 rows=100 loops=1)"
"  ->  Sort  (cost=15708.91..15759.01 rows=20042 width=18) (actual time=19.820..19.831 rows=100 loops=1)"
"        Sort Key: work_date"
"        Sort Method: top-N heapsort  Memory: 36kB"
"        ->  Bitmap Heap Scan on worktime  (cost=273.89..14942.92 rows=20042 width=18) (actual time=2.386..13.871 rows=20646 loops=1)"
"              Filter: (work_date_str ~~ '2023-05%'::text)"
"              Heap Blocks: exact=804"
"              ->  Bitmap Index Scan on idx_worktime_date_pattern  (cost=0.00..268.88 rows=19645 width=0) (actual time=1.739..1.740 rows=20646 loops=1)"
"                    Index Cond: ((work_date_str ~>=~ '2023-05'::text) AND (work_date_str ~<~ '2023-06'::text))"
"Planning Time: 12.173 ms"
"Execution Time: 20.369 ms"

Таким образом, после добавления индекса, время выполнение уменьшилось в 7 раз.

4.2

Задача - 

Запрос для анализа:

EXPLAIN ANALYZE
SELECT worktime_id, employee_id, work_date, hours_worked
FROM WorkTime
WHERE work_date_str ILIKE '%2024%'
ORDER BY worktime_id
LIMIT 100;


Результат без индексов:

"Limit  (cost=0.42..265.72 rows=100 width=18) (actual time=4.264..25.355 rows=100 loops=1)"
"  ->  Index Scan using worktime_pkey on worktime  (cost=0.42..53170.43 rows=20042 width=18) (actual time=4.261..25.328 rows=100 loops=1)"
"        Filter: (work_date_str ~~* '%2024%'::text)"
"        Rows Removed by Filter: 4382"
"Planning Time: 0.396 ms"
"Execution Time: 25.547 ms"


Гипотеза:

Добавим индекс:

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_worktime_date_substring_trgm
ON WorkTime USING gin (work_date_str gin_trgm_ops);



Результат после добавления индекса:

"Limit  (cost=0.42..265.72 rows=100 width=18) (actual time=1.024..3.186 rows=100 loops=1)"
"  ->  Index Scan using worktime_pkey on worktime  (cost=0.42..53170.43 rows=20042 width=18) (actual time=1.023..3.178 rows=100 loops=1)"
"        Filter: (work_date_str ~~* '%2024%'::text)"
"        Rows Removed by Filter: 4382"
"Planning Time: 11.126 ms"
"Execution Time: 3.210 ms"


Таким образом, после добавления индекса, время выполнение уменьшилось в 8 раз.

4.3

Задача - 

Запрос для анализа:

EXPLAIN ANALYZE
SELECT worktime_id, employee_id, work_date, hours_worked
FROM WorkTime
WHERE work_date_str ILIKE '%-15'
ORDER BY worktime_id
LIMIT 100;



Результат без индексов:

"Limit  (cost=0.42..265.72 rows=100 width=18) (actual time=0.039..3.100 rows=100 loops=1)"
"  ->  Index Scan using worktime_pkey on worktime  (cost=0.42..53170.43 rows=20042 width=18) (actual time=0.037..3.088 rows=100 loops=1)"
"        Filter: (work_date_str ~~* '%-15'::text)"
"        Rows Removed by Filter: 2945"
"Planning Time: 0.178 ms"
"Execution Time: 3.127 ms"


Гипотеза:

Добавим индекс:

CREATE INDEX idx_worktime_date_suffix_trgm
ON WorkTime USING gin (work_date_str gin_trgm_ops);



Результат после добавления индекса:

"Limit  (cost=0.42..265.72 rows=100 width=18) (actual time=0.036..1.869 rows=100 loops=1)"
"  ->  Index Scan using worktime_pkey on worktime  (cost=0.42..53170.43 rows=20042 width=18) (actual time=0.035..1.859 rows=100 loops=1)"
"        Filter: (work_date_str ~~* '%-15'::text)"
"        Rows Removed by Filter: 2945"
"Planning Time: 0.197 ms"
"Execution Time: 1.889 ms"

----------------- Пятый сценарий----------------------------

Задача - 

Запрос для тестирования:

EXPLAIN ANALYZE
SELECT e.employee_id, e.first_name, e.last_name,
       SUM(w.hours_worked) AS total_hours
FROM Employee e
JOIN WorkTime w ON w.employee_id = e.employee_id
WHERE w.work_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_hours DESC
LIMIT 100;

Тест без индексов:

"Limit  (cost=22148.74..22148.99 rows=100 width=62) (actual time=206.609..213.550 rows=100 loops=1)"
"  ->  Sort  (cost=22148.74..22151.24 rows=1000 width=62) (actual time=206.607..213.533 rows=100 loops=1)"
"        Sort Key: (sum(w.hours_worked)) DESC"
"        Sort Method: top-N heapsort  Memory: 36kB"
"        ->  Finalize GroupAggregate  (cost=21849.68..22110.53 rows=1000 width=62) (actual time=198.500..211.563 rows=730 loops=1)"
"              Group Key: e.employee_id"
"              ->  Gather Merge  (cost=21849.68..22083.03 rows=2000 width=62) (actual time=198.483..206.477 rows=2190 loops=1)"
"                    Workers Planned: 2"
"                    Workers Launched: 2"
"                    ->  Sort  (cost=20849.65..20852.15 rows=1000 width=62) (actual time=173.712..173.830 rows=730 loops=3)"
"                          Sort Key: e.employee_id"
"                          Sort Method: quicksort  Memory: 116kB"
"                          Worker 0:  Sort Method: quicksort  Memory: 116kB"
"                          Worker 1:  Sort Method: quicksort  Memory: 116kB"
"                          ->  Partial HashAggregate  (cost=20787.32..20799.82 rows=1000 width=62) (actual time=173.035..173.426 rows=730 loops=3)"
"                                Group Key: e.employee_id"
"                                Batches: 1  Memory Usage: 577kB"
"                                Worker 0:  Batches: 1  Memory Usage: 577kB"
"                                Worker 1:  Batches: 1  Memory Usage: 577kB"
"                                ->  Hash Join  (cost=31.50..20274.75 rows=102515 width=36) (actual time=11.640..137.779 rows=81030 loops=3)"
"                                      Hash Cond: (w.employee_id = e.employee_id)"
"                                      ->  Parallel Seq Scan on worktime w  (cost=0.00..19973.00 rows=102515 width=10) (actual time=10.966..95.947 rows=81030 loops=3)"
"                                            Filter: ((work_date >= '2023-01-01'::date) AND (work_date <= '2023-12-31'::date))"
"                                            Rows Removed by Filter: 252303"
"                                      ->  Hash  (cost=19.00..19.00 rows=1000 width=30) (actual time=0.469..0.471 rows=1000 loops=3)"
"                                            Buckets: 1024  Batches: 1  Memory Usage: 71kB"
"                                            ->  Seq Scan on employee e  (cost=0.00..19.00 rows=1000 width=30) (actual time=0.037..0.211 rows=1000 loops=3)"
"Planning Time: 0.306 ms"
"Execution Time: 213.645 ms"

Гипотеза:


Добавим индексы:

CREATE INDEX idx_worktime_covering
ON WorkTime (employee_id, work_date, hours_worked);



Тест с индексами:

"Limit  (cost=13292.17..13292.42 rows=100 width=62) (actual time=121.071..121.085 rows=100 loops=1)"
"  ->  Sort  (cost=13292.17..13294.67 rows=1000 width=62) (actual time=121.069..121.077 rows=100 loops=1)"
"        Sort Key: (sum(w.hours_worked)) DESC"
"        Sort Method: top-N heapsort  Memory: 36kB"
"        ->  GroupAggregate  (cost=0.70..13253.96 rows=1000 width=62) (actual time=0.329..120.213 rows=730 loops=1)"
"              Group Key: e.employee_id"
"              ->  Nested Loop  (cost=0.70..12011.28 rows=246036 width=36) (actual time=0.217..81.286 rows=243090 loops=1)"
"                    ->  Index Scan using employee_pkey on employee e  (cost=0.28..47.27 rows=1000 width=30) (actual time=0.005..0.569 rows=1000 loops=1)"
"                    ->  Index Only Scan using idx_worktime_covering on worktime w  (cost=0.42..9.50 rows=246 width=10) (actual time=0.012..0.051 rows=243 loops=1000)"
"                          Index Cond: ((employee_id = e.employee_id) AND (work_date >= '2023-01-01'::date) AND (work_date <= '2023-12-31'::date))"
"                          Heap Fetches: 0"
"Planning Time: 0.319 ms"
"Execution Time: 121.149 ms"	

Таким образом, скорость увеличилась в 2 раза.




----------------- Шестой сценарий----------------------------


Задача - .

Запрос для проверки:
    
EXPLAIN ANALYZE
SELECT employee_id, work_date, hours_worked
FROM WorkTime
WHERE EXTRACT(MONTH FROM work_date) = 5
ORDER BY work_date
LIMIT 200;



Без индексов:

"Limit  (cost=21063.05..21086.38 rows=200 width=14) (actual time=237.557..246.382 rows=200 loops=1)"
"  ->  Gather Merge  (cost=21063.05..21549.12 rows=4166 width=14) (actual time=237.555..246.364 rows=200 loops=1)"
"        Workers Planned: 2"
"        Workers Launched: 2"
"        ->  Sort  (cost=20063.03..20068.23 rows=2083 width=14) (actual time=205.092..205.106 rows=155 loops=3)"
"              Sort Key: work_date"
"              Sort Method: quicksort  Memory: 40kB"
"              Worker 0:  Sort Method: quicksort  Memory: 37kB"
"              Worker 1:  Sort Method: quicksort  Memory: 35kB"
"              ->  Parallel Seq Scan on worktime  (cost=0.00..19973.00 rows=2083 width=14) (actual time=7.467..204.699 rows=328 loops=3)"
"                    Filter: ((hours_worked + '1'::numeric) = '8'::numeric)"
"                    Rows Removed by Filter: 333006"
"Planning Time: 0.091 ms"
"Execution Time: 227.421 ms"
    

Гипотеза:

CREATE INDEX idx_worktime_date
ON WorkTime (work_date);


С индексами:

"Limit  (cost=21063.05..21086.38 rows=200 width=14) (actual time=179.103..184.309 rows=200 loops=1)"
"  ->  Gather Merge  (cost=21063.05..21549.12 rows=4166 width=14) (actual time=179.101..184.286 rows=200 loops=1)"
"        Workers Planned: 2"
"        Workers Launched: 2"
"        ->  Sort  (cost=20063.03..20068.23 rows=2083 width=14) (actual time=157.278..157.299 rows=158 loops=3)"
"              Sort Key: work_date"
"              Sort Method: quicksort  Memory: 39kB"
"              Worker 0:  Sort Method: quicksort  Memory: 37kB"
"              Worker 1:  Sort Method: quicksort  Memory: 36kB"
"              ->  Parallel Seq Scan on worktime  (cost=0.00..19973.00 rows=2083 width=14) (actual time=10.851..156.185 rows=328 loops=3)"
"                    Filter: ((hours_worked + '1'::numeric) = '8'::numeric)"
"                    Rows Removed by Filter: 333006"
"Planning Time: 0.774 ms"
"Execution Time: 209.357 ms"

