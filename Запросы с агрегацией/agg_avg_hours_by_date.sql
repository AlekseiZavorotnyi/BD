SELECT 
    work_date,
    AVG(hours_worked) AS avg_hours
FROM WorkTime
GROUP BY work_date
ORDER BY work_date;