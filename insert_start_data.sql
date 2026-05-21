INSERT INTO Employee (employee_id, first_name, last_name, birth_date) VALUES
(1, 'Алексей', 'Иванов', '1995-03-12'),
(2, 'Мария', 'Петрова', '1990-07-22'),
(3, 'Игорь', 'Сидоров', '1988-11-05'),
(4, 'Анна', 'Кузнецова', '1997-02-14'),
(5, 'Дмитрий', 'Смирнов', '1992-12-01');

INSERT INTO Dogovors (dogovor_id, position, start_date, end_date, salary, department, employee_id) VALUES
(1, 'Software Engineer', '2020-01-15', '2023-01-14', 150000, 'IT', 1),
(2, 'HR Manager', '2018-03-10', '2023-03-09', 90000, 'HR', 2),
(3, 'Data Analyst', '2019-09-01', '2024-08-31', 120000, 'Finance', 3),
(4, 'Marketing Specialist', '2021-06-20', '2022-06-19', 80000, 'Marketing', 4),
(5, 'System Administrator', '2017-04-18', NULL, 110000, 'IT', 5);

INSERT INTO Vacation (vacation_id, employee_id, start_date, end_date, type) VALUES
(1, 1, '2023-06-01', '2023-06-14', 'Оплачиваемый'),
(2, 2, '2023-07-10', '2023-07-20', 'Оплачиваемый'),
(3, 3, '2023-08-05', '2023-08-12', 'Больничный'),
(4, 1, '2024-01-15', '2024-01-22', 'Оплачиваемый');

INSERT INTO WorkTime (worktime_id, employee_id, work_date, hours_worked) VALUES
(1, 1, '2024-03-01', 8),
(2, 1, '2024-03-02', 7.5),
(3, 2, '2024-03-01', 8),
(4, 3, '2024-03-01', 6),
(5, 3, '2024-03-02', 8),
(6, 4, '2024-03-01', 8),
(7, 5, '2024-03-01', 8),
(8, 5, '2024-03-02', 8),
(9, 1, '2024-03-03', 8),
(10, 2, '2024-03-03', 7);