SELECT
    MIN(end_date - start_date) AS min_days,
    MAX(end_date - start_date) AS max_days,
    AVG(end_date - start_date) AS avg_days
FROM Vacation;