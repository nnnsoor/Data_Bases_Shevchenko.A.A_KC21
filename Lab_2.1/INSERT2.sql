USE Farm_Management_Shevchenko;
GO

DELETE FROM FERTILIZER_APPLICATION;
DELETE FROM WORKER_EQUIPMENT_SKILL;
DELETE FROM WORKER;
DELETE FROM EQUIPMENT;
DELETE FROM LAND_PLOT;
DELETE FROM FERTILIZER;
DELETE FROM CROP;
DELETE FROM BRIGADE;
GO

DECLARE @i INT = 1;
WHILE @i <= 50
BEGIN
    INSERT INTO BRIGADE (brigade_id, foreman_first_name, foreman_last_name, foreman_patronymic, formation_date)
    VALUES (@i, 'Ім''я' + CAST(@i AS VARCHAR), 'Прізвище' + CAST(@i AS VARCHAR), 'По батькові' + CAST(@i AS VARCHAR), DATEADD(day, -(@i * 100), GETDATE()));
    SET @i = @i + 1;
END;

SET @i = 1;
WHILE @i <= 100
BEGIN
    INSERT INTO CROP (crop_id, crop_name, average_yield, requires_irrigation, growing_season_days)
    VALUES (@i, 'Культура_' + CAST(@i AS VARCHAR), 10 + (@i % 20), @i % 2, 60 + (@i % 100));
    SET @i = @i + 1;
END;

SET @i = 1;
WHILE @i <= 200
BEGIN
    INSERT INTO FERTILIZER (fertilizer_id, fertilizer_name, fertilizer_type, nitrogen_percent, phosphorus_percent, potassium_percent, application_rate)
    VALUES (@i, 'Добриво_' + CAST(@i AS VARCHAR), CASE WHEN @i % 2 = 0 THEN 'Органічне' ELSE 'Мінеральне' END, @i % 30, @i % 20, @i % 15, 100 + (@i % 200));
    SET @i = @i + 1;
END;

SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO LAND_PLOT (plot_id, area, has_irrigation, soil_quality_index, brigade_id, crop_id)
    VALUES (@i, 0.5 + (@i % 100), @i % 2, 5 + (@i % 5), (@i % 50) + 1, CASE WHEN @i % 3 = 0 THEN NULL ELSE (@i % 100) + 1 END);
    SET @i = @i + 1;
END;

SET @i = 1;
WHILE @i <= 2000
BEGIN
    INSERT INTO WORKER (worker_id, first_name, last_name, patronymic, hire_date, phone_number, brigade_id)
    VALUES (@i, 'Працівник_ім''я' + CAST(@i AS VARCHAR), 'Працівник_прізвище' + CAST(@i AS VARCHAR), 'Працівник_по_батькові' + CAST(@i AS VARCHAR), DATEADD(day, -(@i * 5), GETDATE()), '380' + RIGHT('000000000' + CAST(@i AS VARCHAR), 9), (@i % 50) + 1);
    SET @i = @i + 1;
END;

SET @i = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO EQUIPMENT (equipment_id, equipment_type, model, manufacture_year, purchase_date, status, brigade_id)
    VALUES (@i, CASE WHEN @i % 3 = 0 THEN 'Трактор' WHEN @i % 3 = 1 THEN 'Комбайн' ELSE 'Сівалка' END, 'Модель_' + CAST(@i AS VARCHAR), 2000 + (@i % 23), DATEADD(day, -(@i * 30), GETDATE()), CASE WHEN @i % 5 = 0 THEN 'На ремонті' ELSE 'Робоча' END, (@i % 50) + 1);
    SET @i = @i + 1;
END;

SET @i = 1;
WHILE @i <= 3000
BEGIN
    INSERT INTO WORKER_EQUIPMENT_SKILL (skill_id, worker_id, equipment_id, skill_level, certification_date, experience_years)
    VALUES (@i, (@i % 2000) + 1, (@i % 500) + 1, CASE WHEN @i % 3 = 0 THEN 'Початківець' WHEN @i % 3 = 1 THEN 'Середній' ELSE 'Експерт' END, DATEADD(day, -(@i * 10), GETDATE()), @i % 15);
    SET @i = @i + 1;
END;

SET @i = 1;
WHILE @i <= 5000
BEGIN
    INSERT INTO FERTILIZER_APPLICATION (application_id, plot_id, fertilizer_id, worker_id, brigade_id, application_date, amount_kg, application_method, notes)
    VALUES (@i, (@i % 1000) + 1, (@i % 200) + 1, (@i % 2000) + 1, (@i % 50) + 1, DATEADD(day, -(@i * 2), GETDATE()), 50 + (@i % 500), CASE WHEN @i % 2 = 0 THEN 'Розпилення' ELSE 'Розкидання' END, 'Примітка_' + CAST(@i AS VARCHAR));
    SET @i = @i + 1;
END;

SELECT 'BRIGADE' AS TableName, COUNT(*) AS Records FROM BRIGADE
UNION ALL SELECT 'CROP', COUNT(*) FROM CROP
UNION ALL SELECT 'FERTILIZER', COUNT(*) FROM FERTILIZER
UNION ALL SELECT 'LAND_PLOT', COUNT(*) FROM LAND_PLOT
UNION ALL SELECT 'WORKER', COUNT(*) FROM WORKER
UNION ALL SELECT 'EQUIPMENT', COUNT(*) FROM EQUIPMENT
UNION ALL SELECT 'WORKER_EQUIPMENT_SKILL', COUNT(*) FROM WORKER_EQUIPMENT_SKILL
UNION ALL SELECT 'FERTILIZER_APPLICATION', COUNT(*) FROM FERTILIZER_APPLICATION
ORDER BY TableName;