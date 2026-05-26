DROP VIEW IF EXISTS view_employee_hours_summary CASCADE;

CREATE VIEW view_employee_hours_summary AS
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    COALESCE(SUM(w.hours_worked), 0) AS total_hours,
	AVG(w.hours_worked) AS avg_hours_worked_per_day
FROM Employee e
LEFT JOIN WorkTime w ON e.employee_id = w.employee_id
GROUP BY e.employee_id
ORDER BY e.employee_id;
