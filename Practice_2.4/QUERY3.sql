USE Farm_Management_Shevchenko;
GO

DELETE FROM Fertilizer_Application;
DELETE FROM Worker_Equipment_Skill;
DELETE FROM Worker;
DELETE FROM Equipment;
DELETE FROM Land_Plot;
DELETE FROM Fertilizer;
DELETE FROM Crop;
DELETE FROM Brigade;
GO

-- Brigade
DECLARE @i INT = 1;
WHILE @i <= 110
BEGIN
    INSERT INTO Brigade (brigade_id, foreman_first_name, foreman_last_name, foreman_patronymic, formation_date)
    VALUES (
        @i,
        CASE (@i % 10)
            WHEN 1 THEN N'Іван'    WHEN 2 THEN N'Марія'   WHEN 3 THEN N'Олег'
            WHEN 4 THEN N'Наталія' WHEN 5 THEN N'Петро'   WHEN 6 THEN N'Ольга'
            WHEN 7 THEN N'Андрій'  WHEN 8 THEN N'Тетяна'  WHEN 9 THEN N'Василь'
            ELSE        N'Людмила'
        END,
        CASE (@i % 20)
            WHEN 1  THEN N'Петренко'  WHEN 2  THEN N'Коваленко'
            WHEN 3  THEN N'Шевченко'  WHEN 4  THEN N'Бондаренко'
            WHEN 5  THEN N'Лисенко'   WHEN 6  THEN N'Мельник'
            WHEN 7  THEN N'Кравченко' WHEN 8  THEN N'Гончаренко'
            WHEN 9  THEN N'Кириленко' WHEN 10 THEN N'Остапенко'
            WHEN 11 THEN N'Власенко'  WHEN 12 THEN N'Даниленко'
            WHEN 13 THEN N'Євтушенко' WHEN 14 THEN N'Карпенко'
            WHEN 15 THEN N'Лазаренко' WHEN 16 THEN N'Матвієнко'
            WHEN 17 THEN N'Назаренко' WHEN 18 THEN N'Олексієнко'
            WHEN 19 THEN N'Пилипенко' ELSE     N'Романенко'
        END,
        CASE (@i % 5)
            WHEN 1 THEN N'Іванович'   WHEN 2 THEN N'Олексійович'
            WHEN 3 THEN N'Васильович' WHEN 4 THEN N'Петрович'
            ELSE        N'Миколайович'
        END,
        DATEADD(DAY, -@i * 30, '2026-01-01')
    );
    SET @i = @i + 1;
END
GO

-- Crop
DECLARE @i INT = 1;
WHILE @i <= 110
BEGIN
    INSERT INTO Crop (crop_id, crop_name, average_yield, requires_irrigation, growing_season_days)
    VALUES (
        @i,
        CASE ((@i - 1) % 22)
            WHEN 0  THEN N'Пшениця озима'  WHEN 1  THEN N'Пшениця яра'
            WHEN 2  THEN N'Кукурудза'      WHEN 3  THEN N'Соняшник'
            WHEN 4  THEN N'Ріпак озимий'   WHEN 5  THEN N'Ріпак ярий'
            WHEN 6  THEN N'Ячмінь озимий'  WHEN 7  THEN N'Ячмінь ярий'
            WHEN 8  THEN N'Жито'           WHEN 9  THEN N'Овес'
            WHEN 10 THEN N'Гречка'         WHEN 11 THEN N'Просо'
            WHEN 12 THEN N'Соя'            WHEN 13 THEN N'Горох'
            WHEN 14 THEN N'Буряк цукровий' WHEN 15 THEN N'Картопля'
            WHEN 16 THEN N'Льон'           WHEN 17 THEN N'Сорго'
            WHEN 18 THEN N'Тритикале'      WHEN 19 THEN N'Вика'
            WHEN 20 THEN N'Люпин'
            ELSE         N'Квасоля'
        END + N' (сорт ' + CAST(@i AS NVARCHAR(5)) + N')',
        CAST(20 + (@i % 80) AS DECIMAL(10,2)),
        CAST(@i % 2 AS BIT),
        90 + (@i % 200)
    );
    SET @i = @i + 1;
END
GO

-- Fertilizer
DECLARE @i INT = 1;
WHILE @i <= 110
BEGIN
    INSERT INTO Fertilizer
        (fertilizer_id, fertilizer_name, fertilizer_type, application_rate,
         nitrogen_percent, phosphorus_percent, potassium_percent)
    VALUES (
        @i,
        CASE ((@i - 1) % 11)
            WHEN 0  THEN N'Нітроамофоска'   WHEN 1  THEN N'Аміачна селітра'
            WHEN 2  THEN N'Карбамід'        WHEN 3  THEN N'Суперфосфат'
            WHEN 4  THEN N'Хлористий калій' WHEN 5  THEN N'Сульфат амонію'
            WHEN 6  THEN N'Гній'            WHEN 7  THEN N'Компост'
            WHEN 8  THEN N'Зола деревна'    WHEN 9  THEN N'Біогумус'
            ELSE         N'Мікродобриво'
        END + N' №' + CAST(@i AS NVARCHAR(5)),
        CASE (@i % 3)
            WHEN 0 THEN N'мінеральне'
            WHEN 1 THEN N'органічне'
            ELSE        N'органо-мінеральне'
        END,
        CAST(100 + (@i * 45) % 5000 AS DECIMAL(10,2)),
        CAST((@i * 3) % 35 AS DECIMAL(5,2)),
        CAST((@i * 2) % 20 AS DECIMAL(5,2)),
        CAST((@i * 4) % 25 AS DECIMAL(5,2))
    );
    SET @i = @i + 1;
END
GO

-- Land_Plot
DECLARE @i INT = 1;
WHILE @i <= 110
BEGIN
    INSERT INTO Land_Plot (plot_id, area, has_irrigation, soil_quality_index, brigade_id, crop_id)
    VALUES (
        @i,
        CAST(10 + (@i * 7) % 200 AS DECIMAL(10,2)),
        CAST(@i % 2 AS BIT),
        CAST(4.0 + (@i % 60) * 0.1 AS DECIMAL(5,2)),
        @i,
        @i
    );
    SET @i = @i + 1;
END
GO

-- Worker (без email)
DECLARE @i INT = 1;
WHILE @i <= 110
BEGIN
    INSERT INTO Worker
        (worker_id, brigade_id, first_name, last_name, patronymic, hire_date, phone_number)
    VALUES (
        @i,
        ((@i - 1) % 110) + 1,
        CASE (@i % 10)
            WHEN 1 THEN N'Іван'    WHEN 2 THEN N'Марія'   WHEN 3 THEN N'Олег'
            WHEN 4 THEN N'Наталія' WHEN 5 THEN N'Петро'   WHEN 6 THEN N'Ольга'
            WHEN 7 THEN N'Андрій'  WHEN 8 THEN N'Тетяна'  WHEN 9 THEN N'Василь'
            ELSE        N'Людмила'
        END,
        CASE (@i % 20)
            WHEN 1  THEN N'Петренко'  WHEN 2  THEN N'Коваленко'
            WHEN 3  THEN N'Шевченко'  WHEN 4  THEN N'Бондаренко'
            WHEN 5  THEN N'Лисенко'   WHEN 6  THEN N'Мельник'
            WHEN 7  THEN N'Кравченко' WHEN 8  THEN N'Гончаренко'
            WHEN 9  THEN N'Кириленко' WHEN 10 THEN N'Остапенко'
            WHEN 11 THEN N'Власенко'  WHEN 12 THEN N'Даниленко'
            WHEN 13 THEN N'Євтушенко' WHEN 14 THEN N'Карпенко'
            WHEN 15 THEN N'Лазаренко' WHEN 16 THEN N'Матвієнко'
            WHEN 17 THEN N'Назаренко' WHEN 18 THEN N'Олексієнко'
            WHEN 19 THEN N'Пилипенко' ELSE     N'Романенко'
        END,
        CASE (@i % 5)
            WHEN 1 THEN N'Іванович'   WHEN 2 THEN N'Олексійович'
            WHEN 3 THEN N'Васильович' WHEN 4 THEN N'Петрович'
            ELSE        N'Миколайович'
        END,
        DATEADD(DAY, -((@i * 17) % 3650), '2026-01-01'),
        N'0' + CAST(50 + (@i % 10) AS NVARCHAR(2)) + N'-' +
            CAST(100 + @i % 900 AS NVARCHAR(3)) + N'-' +
            CAST(10 + @i % 90  AS NVARCHAR(2)) + N'-' +
            CAST(10 + @i % 90  AS NVARCHAR(2))
    );
    SET @i = @i + 1;
END
GO

-- Equipment (з brigade_id)
DECLARE @i INT = 1;
WHILE @i <= 110
BEGIN
    INSERT INTO Equipment (equipment_id, equipment_type, model, manufacture_year, purchase_date, status, brigade_id)
    VALUES (
        @i,
        CASE ((@i - 1) % 7)
            WHEN 0 THEN N'Трактор'     WHEN 1 THEN N'Комбайн'
            WHEN 2 THEN N'Обприскувач' WHEN 3 THEN N'Сівалка'
            WHEN 4 THEN N'Культиватор' WHEN 5 THEN N'Плуг'
            ELSE        N'Борона'
        END,
        CASE ((@i - 1) % 10)
            WHEN 0 THEN N'John Deere '  + CAST(6000 + @i AS NVARCHAR(6))
            WHEN 1 THEN N'Claas Lexion '+ CAST(500  + @i AS NVARCHAR(6))
            WHEN 2 THEN N'Hardi Nav '   + CAST(400  + @i AS NVARCHAR(6))
            WHEN 3 THEN N'Amazone D9 '  + CAST(@i AS NVARCHAR(6))
            WHEN 4 THEN N'Horsch Tiger '+ CAST(@i AS NVARCHAR(6))
            WHEN 5 THEN N'Lemken Vari ' + CAST(@i AS NVARCHAR(6))
            WHEN 6 THEN N'Kverneland '  + CAST(@i AS NVARCHAR(6))
            WHEN 7 THEN N'New Holland T'+ CAST(@i AS NVARCHAR(6))
            WHEN 8 THEN N'Case IH '     + CAST(@i AS NVARCHAR(6))
            ELSE        N'FENDT '       + CAST(200 + @i AS NVARCHAR(6))
        END,
        2015 + (@i % 10),
        DATEADD(MONTH, -(@i % 48), '2026-01-01'),
        CASE (@i % 4)
            WHEN 0 THEN N'на ремонті'
            ELSE        N'справний'
        END,
        ((@i - 1) % 110) + 1
    );
    SET @i = @i + 1;
END
GO

-- Worker_Equipment_Skill
DECLARE @i INT = 1;
WHILE @i <= 110
BEGIN
    INSERT INTO Worker_Equipment_Skill
        (skill_id, worker_id, equipment_id, skill_level, certification_date, experience_years)
    VALUES (
        @i, @i, @i,
        1 + (@i % 5),
        DATEADD(MONTH, -(@i % 36), '2026-01-01'),
        (@i % 15) + 1
    );
    SET @i = @i + 1;
END
GO

-- Fertilizer_Application (worker_id і brigade_id)
DECLARE @i INT = 1;
WHILE @i <= 110
BEGIN
    INSERT INTO Fertilizer_Application
        (application_id, plot_id, fertilizer_id, worker_id, brigade_id,
         application_date, amount_kg, application_method)
    VALUES (
        @i, @i, @i, @i, @i,
        DATEADD(DAY, -(@i * 3) % 365, '2025-12-31'),
        CAST(500 + (@i * 137) % 50000 AS DECIMAL(10,2)),
        CASE (@i % 4)
            WHEN 0 THEN N'розкидання'
            WHEN 1 THEN N'внесення в ґрунт'
            WHEN 2 THEN N'гноєрозкидач'
            ELSE        N'обприскування'
        END
    );
    SET @i = @i + 1;
END
GO


-- ЗАВДАННЯ 2
SELECT 'Brigade'                AS table_name, COUNT(*) AS record_count FROM Brigade
UNION ALL
SELECT 'Crop',                             COUNT(*) FROM Crop
UNION ALL
SELECT 'Land_Plot',                        COUNT(*) FROM Land_Plot
UNION ALL
SELECT 'Fertilizer',                       COUNT(*) FROM Fertilizer
UNION ALL
SELECT 'Worker',                           COUNT(*) FROM Worker
UNION ALL
SELECT 'Equipment',                        COUNT(*) FROM Equipment
UNION ALL
SELECT 'Worker_Equipment_Skill',           COUNT(*) FROM Worker_Equipment_Skill
UNION ALL
SELECT 'Fertilizer_Application',           COUNT(*) FROM Fertilizer_Application;
GO


-- ЗАВДАННЯ 3

SELECT
    b.brigade_id,
    CONCAT(b.foreman_last_name, N' ', b.foreman_first_name) AS brigade_head,
    COUNT(lp.plot_id)   AS plot_count,
    SUM(lp.area)        AS total_area,
    AVG(lp.area)        AS avg_area,
    MIN(lp.area)        AS min_area,
    MAX(lp.area)        AS max_area
FROM Brigade b
LEFT JOIN Land_Plot lp ON b.brigade_id = lp.brigade_id
GROUP BY b.brigade_id, b.foreman_last_name, b.foreman_first_name
HAVING COUNT(lp.plot_id) > 0
ORDER BY total_area DESC;
GO

SELECT
    c.crop_id,
    c.crop_name,
    COUNT(lp.plot_id)                                               AS plots_count,
    CAST(AVG(lp.soil_quality_index) AS DECIMAL(5,2))               AS avg_quality,
    MIN(lp.soil_quality_index)                                      AS min_quality,
    MAX(lp.soil_quality_index)                                      AS max_quality,
    CAST(MAX(lp.soil_quality_index) - MIN(lp.soil_quality_index)
         AS DECIMAL(5,2))                                           AS quality_range
FROM Crop c
JOIN Land_Plot lp ON c.crop_id = lp.crop_id
WHERE lp.soil_quality_index IS NOT NULL
GROUP BY c.crop_id, c.crop_name
HAVING COUNT(lp.plot_id) >= 1
ORDER BY avg_quality DESC;
GO

SELECT
    f.fertilizer_type,
    COUNT(fa.application_id)                        AS total_applications,
    SUM(fa.amount_kg)                               AS total_amount_kg,
    CAST(AVG(fa.amount_kg) AS DECIMAL(10,2))        AS avg_amount_kg,
    MAX(fa.amount_kg)                               AS max_single_application,
    MIN(fa.amount_kg)                               AS min_single_application,
    COUNT(DISTINCT fa.plot_id)                      AS unique_plots_treated
FROM Fertilizer f
JOIN Fertilizer_Application fa ON f.fertilizer_id = fa.fertilizer_id
GROUP BY f.fertilizer_type
ORDER BY total_amount_kg DESC;
GO


-- ЗАВДАННЯ 4

SELECT
    w.worker_id,
    CONCAT(w.last_name, N' ', w.first_name)     AS worker_name,
    w.brigade_id,
    w.hire_date,
    DATEDIFF(YEAR, w.hire_date, GETDATE())       AS years_of_service,
    ROW_NUMBER() OVER (
        PARTITION BY w.brigade_id
        ORDER BY w.hire_date ASC
    )                                            AS seniority_rank
FROM Worker w
ORDER BY w.brigade_id, seniority_rank;
GO

SELECT
    fa.application_id,
    fa.plot_id,
    fa.application_date,
    fa.amount_kg,
    SUM(fa.amount_kg) OVER (
        PARTITION BY fa.plot_id
        ORDER BY fa.application_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                           AS running_total_per_plot,
    SUM(fa.amount_kg) OVER (
        PARTITION BY fa.plot_id
    )                           AS grand_total_per_plot
FROM Fertilizer_Application fa
ORDER BY fa.plot_id, fa.application_date;
GO

SELECT
    lp.plot_id,
    lp.brigade_id,
    lp.area,
    lp.soil_quality_index,
    RANK() OVER (
        ORDER BY lp.soil_quality_index DESC
    )                           AS quality_rank,
    DENSE_RANK() OVER (
        ORDER BY lp.soil_quality_index DESC
    )                           AS quality_dense_rank,
    NTILE(4) OVER (
        ORDER BY lp.soil_quality_index DESC
    )                           AS quality_quartile
FROM Land_Plot lp
WHERE lp.soil_quality_index IS NOT NULL
ORDER BY quality_rank;
GO


-- ЗАВДАННЯ 5

SELECT
    worker_id,
    UPPER(last_name)                                    AS last_name_upper,
    LOWER(first_name)                                   AS first_name_lower,
    CONCAT(last_name, N' ', first_name,
           CASE WHEN patronymic IS NOT NULL
                THEN N' ' + patronymic
                ELSE N'' END)                           AS full_name,
    LEN(CONCAT(last_name, N' ', first_name))            AS name_length,
    REPLICATE(N'*', LEN(last_name))                     AS masked_last_name
FROM Worker
ORDER BY last_name, first_name;
GO

SELECT
    worker_id,
    CONCAT(last_name, N' ', first_name)                 AS worker_name,
    phone_number,
    LEFT(phone_number, 3)                               AS phone_code,
    SUBSTRING(phone_number,
              CHARINDEX(N'-', phone_number) + 1,
              3)                                        AS area_part,
    REPLACE(phone_number, N'-', N'')                    AS phone_digits_only,
    LEN(REPLACE(phone_number, N'-', N''))               AS digit_count
FROM Worker
WHERE phone_number IS NOT NULL
ORDER BY worker_id;
GO

SELECT
    equipment_id,
    equipment_type,
    model,
    UPPER(TRIM(equipment_type))                         AS type_normalized,
    LEFT(model, CHARINDEX(N' ', model + N' ') - 1)      AS brand,
    LTRIM(SUBSTRING(model,
                    CHARINDEX(N' ', model),
                    LEN(model)))                        AS model_code,
    LEN(model)                                          AS model_length
FROM Equipment
WHERE model IS NOT NULL
ORDER BY brand, equipment_type;
GO


-- ЗАВДАННЯ 6

SELECT
    worker_id,
    CONCAT(last_name, N' ', first_name)         AS worker_name,
    hire_date,
    GETDATE()                                   AS server_date,
    DATEDIFF(YEAR,  hire_date, GETDATE())        AS years_of_service,
    DATEDIFF(MONTH, hire_date, GETDATE())        AS months_of_service,
    DATEDIFF(DAY,   hire_date, GETDATE())        AS days_of_service,
    CASE
        WHEN DATEDIFF(YEAR, hire_date, GETDATE()) >= 10 THEN N'Ветеран'
        WHEN DATEDIFF(YEAR, hire_date, GETDATE()) >=  5 THEN N'Досвідчений'
        WHEN DATEDIFF(YEAR, hire_date, GETDATE()) >=  1 THEN N'Стажист'
        ELSE                                                  N'Новачок'
    END                                         AS experience_category
FROM Worker
ORDER BY hire_date ASC;
GO

SELECT
    DATEPART(YEAR,    application_date)                     AS [year],
    DATEPART(MONTH,   application_date)                     AS month_num,
    DATENAME(MONTH,   application_date)                     AS month_name,
    DATEPART(QUARTER, application_date)                     AS quarter_num,
    COUNT(*)                                                AS applications_count,
    SUM(amount_kg)                                          AS total_amount_kg,
    FORMAT(MIN(application_date), N'dd.MM.yyyy')            AS first_application,
    FORMAT(MAX(application_date), N'dd.MM.yyyy')            AS last_application
FROM Fertilizer_Application
GROUP BY
    DATEPART(YEAR,    application_date),
    DATEPART(MONTH,   application_date),
    DATENAME(MONTH,   application_date),
    DATEPART(QUARTER, application_date)
ORDER BY [year], month_num;
GO

SELECT
    wes.skill_id,
    CONCAT(w.last_name, N' ', w.first_name)                 AS worker_name,
    e.equipment_type,
    e.model,
    wes.certification_date,
    FORMAT(wes.certification_date, N'dd.MM.yyyy')           AS cert_date_fmt,
    DATEADD(YEAR, 3, wes.certification_date)                AS expiry_date,
    FORMAT(DATEADD(YEAR, 3, wes.certification_date),
           N'dd.MM.yyyy')                                   AS expiry_fmt,
    DATEDIFF(DAY, GETDATE(),
             DATEADD(YEAR, 3, wes.certification_date))      AS days_until_expiry,
    CASE
        WHEN DATEADD(YEAR, 3, wes.certification_date) < GETDATE()
            THEN N'ПРОСТРОЧЕНО'
        WHEN DATEDIFF(DAY, GETDATE(),
                      DATEADD(YEAR, 3, wes.certification_date)) <= 90
            THEN N'ЗАКІНЧУЄТЬСЯ СКОРО'
        ELSE N'Дійсна'
    END                                                     AS cert_status
FROM Worker_Equipment_Skill wes
JOIN Worker    w ON wes.worker_id    = w.worker_id
JOIN Equipment e ON wes.equipment_id = e.equipment_id
WHERE wes.certification_date IS NOT NULL
ORDER BY expiry_date ASC;
GO