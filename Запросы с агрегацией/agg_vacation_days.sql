SELECT 
    vacation_id,
    (end_date - start_date) AS days_count
FROM Vacation
ORDER BY days_count DESC;