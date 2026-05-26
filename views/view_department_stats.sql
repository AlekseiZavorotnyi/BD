DROP VIEW IF EXISTS view_department_stats CASCADE;

CREATE VIEW view_department_stats AS
SELECT 
    d.department,
    COUNT(DISTINCT d.employee_id) AS employees_count,
    AVG(d.salary) AS avg_salary
FROM Dogovors d
GROUP BY d.department;