DROP TABLE IF EXISTS WorkTime CASCADE;
DROP TABLE IF EXISTS Vacation CASCADE;
DROP TABLE IF EXISTS Dogovors CASCADE;
DROP TABLE IF EXISTS Employee CASCADE;

CREATE TABLE Employee (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE
);

CREATE TABLE Dogovors (
    dogovor_id INT PRIMARY KEY,
    position VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    salary DECIMAL(10,2) NOT NULL,
    department VARCHAR(100) NOT NULL,
    employee_id INT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee(employee_id)
);

CREATE TABLE Vacation (
    vacation_id INT PRIMARY KEY,
    employee_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    type VARCHAR(50),
    FOREIGN KEY (employee_id) REFERENCES Employee(employee_id)
);

CREATE TABLE WorkTime (
    worktime_id INT PRIMARY KEY,
    employee_id INT NOT NULL,
    work_date DATE NOT NULL,
    hours_worked DECIMAL(4,2) NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee(employee_id)
);