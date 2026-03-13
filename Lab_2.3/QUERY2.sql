USE Farm_Management_Shevchenko;
GO

SELECT
    lp.plot_id,
    lp.area,
    lp.has_irrigation,
    lp.soil_quality_index,
    b.foreman_first_name + ' ' + b.foreman_last_name AS brigadier,
    c.crop_name,
    c.average_yield
FROM Land_Plot lp
INNER JOIN Brigade b ON lp.brigade_id = b.brigade_id
INNER JOIN Crop c    ON lp.crop_id    = c.crop_id;
GO

SELECT
    fa.application_id,
    w.first_name + ' ' + w.last_name AS worker_name,
    lp.plot_id,
    lp.area,
    f.fertilizer_name,
    f.fertilizer_type,
    fa.amount_kg,
    fa.application_date,
    fa.application_method
FROM Fertilizer_Application fa
INNER JOIN Worker    w  ON fa.worker_id = w.worker_id
INNER JOIN Land_Plot lp ON fa.plot_id              = lp.plot_id
INNER JOIN Fertilizer f ON fa.fertilizer_id        = f.fertilizer_id;
GO

SELECT
    lp.plot_id,
    lp.area,
    c.crop_name,
    c.average_yield
FROM Land_Plot lp
INNER JOIN Crop c ON lp.crop_id = c.crop_id
WHERE c.average_yield = (SELECT MAX(average_yield) FROM Crop);
GO

SELECT
    'Бригадир'           AS role,
    foreman_first_name   AS first_name,
    foreman_last_name    AS last_name,
    foreman_patronymic   AS patronymic
FROM Brigade
UNION ALL
SELECT
    'Працівник',
    first_name,
    last_name,
    patronymic
FROM Worker
ORDER BY role, last_name;
GO

SELECT
    b.brigade_id,
    b.foreman_first_name + ' ' + b.foreman_last_name AS brigadier,
    b.formation_date
FROM Brigade b
WHERE EXISTS (
    SELECT 1
    FROM Land_Plot lp
    WHERE lp.brigade_id = b.brigade_id
      AND lp.has_irrigation = 1
);
GO


IF OBJECT_ID('Test_Fert_Log', 'U') IS NOT NULL DROP TABLE Test_Fert_Log;
IF OBJECT_ID('Test_Plot',     'U') IS NOT NULL DROP TABLE Test_Plot;
IF OBJECT_ID('Test_Brigade',  'U') IS NOT NULL DROP TABLE Test_Brigade;
GO

CREATE TABLE Test_Brigade (
    brigade_id   INT           PRIMARY KEY,
    brigade_name NVARCHAR(100) NOT NULL
);

CREATE TABLE Test_Plot (
    plot_id    INT           PRIMARY KEY,
    brigade_id INT           NOT NULL,
    area       DECIMAL(10,2),
    CONSTRAINT FK_TestPlot_Brigade FOREIGN KEY (brigade_id)
        REFERENCES Test_Brigade(brigade_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Test_Fert_Log (
    log_id           INT IDENTITY(1,1) PRIMARY KEY,
    plot_id          INT           NOT NULL,
    fertilizer_name  NVARCHAR(100),
    application_date DATE,
    CONSTRAINT FK_TestLog_Plot FOREIGN KEY (plot_id)
        REFERENCES Test_Plot(plot_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

INSERT INTO Test_Brigade VALUES (1, 'Бригада Альфа'), (2, 'Бригада Бета');
INSERT INTO Test_Plot   VALUES (10, 1, 45.5), (11, 1, 30.0), (12, 2, 60.0);
INSERT INTO Test_Fert_Log (plot_id, fertilizer_name, application_date) VALUES
    (10, 'Нітроамофоска',   '2025-04-10'),
    (10, 'Аміачна селітра', '2025-04-15'),
    (11, 'Гній',            '2025-04-12'),
    (12, 'Суперфосфат',     '2025-04-18');
GO

PRINT '=== ДО UPDATE CASCADE ===';
SELECT * FROM Test_Plot;

UPDATE Test_Brigade SET brigade_id = 100 WHERE brigade_id = 1;

PRINT '=== ПІСЛЯ UPDATE CASCADE (brigade_id 1 -> 100) ===';
SELECT * FROM Test_Plot;
GO
PRINT '=== ДО DELETE CASCADE (бригада 2) ===';
SELECT * FROM Test_Plot     WHERE brigade_id = 2;
SELECT * FROM Test_Fert_Log WHERE plot_id    = 12;

DELETE FROM Test_Brigade WHERE brigade_id = 2;

PRINT '=== ПІСЛЯ DELETE CASCADE (бригада 2 видалена — рядки мають бути відсутні) ===';
SELECT * FROM Test_Plot     WHERE brigade_id = 2;
SELECT * FROM Test_Fert_Log WHERE plot_id    = 12;
GO

PRINT '=== ДО DELETE CASCADE (ділянка 10) ===';
SELECT * FROM Test_Fert_Log WHERE plot_id = 10;

DELETE FROM Test_Plot WHERE plot_id = 10;

PRINT '=== ПІСЛЯ DELETE CASCADE (ділянка 10 видалена — рядки мають бути відсутні) ===';
SELECT * FROM Test_Fert_Log WHERE plot_id = 10;
GO

DROP TABLE Test_Fert_Log;
DROP TABLE Test_Plot;
DROP TABLE Test_Brigade;
GO

SELECT
    plot_id,
    area,
    soil_quality_index,
    has_irrigation
FROM Land_Plot
ORDER BY area DESC;
GO

SELECT
    crop_name,
    average_yield,
    requires_irrigation,
    growing_season_days
FROM Crop
ORDER BY average_yield ASC;
GO

SELECT
    worker_id,
    last_name,
    first_name,
    hire_date,
    brigade_id
FROM Worker
ORDER BY hire_date ASC;
GO

SELECT
    fa.application_id,
    fa.application_date,
    f.fertilizer_name,
    fa.amount_kg,
    fa.application_method
FROM Fertilizer_Application fa
INNER JOIN Fertilizer f ON fa.fertilizer_id = f.fertilizer_id
ORDER BY fa.application_date DESC, fa.amount_kg DESC;
GO

SELECT
    equipment_id,
    equipment_type,
    model,
    manufacture_year,
    status
FROM Equipment
ORDER BY manufacture_year DESC, model ASC;
GO

SELECT
    plot_id,
    area,
    has_irrigation,
    soil_quality_index
FROM Land_Plot
WHERE has_irrigation = 1 AND area > 40;
GO

SELECT
    crop_name,
    average_yield,
    requires_irrigation,
    growing_season_days
FROM Crop
WHERE requires_irrigation = 0 OR growing_season_days < 140;
GO

SELECT
    fertilizer_name,
    fertilizer_type,
    nitrogen_percent
FROM Fertilizer
WHERE NOT fertilizer_type = 'органічне';
GO

SELECT
    last_name,
    first_name,
    hire_date,
    brigade_id
FROM Worker
WHERE hire_date >= '2021-01-01' AND hire_date <= '2022-12-31';
GO

SELECT
    equipment_type,
    model,
    manufacture_year,
    status
FROM Equipment
WHERE status <> 'справний';
GO

SELECT
    plot_id,
    area,
    soil_quality_index,
    has_irrigation
FROM Land_Plot
WHERE soil_quality_index > 7.0
  AND (area > 60 OR has_irrigation = 1);
GO

SELECT
    lp.plot_id,
    lp.area,
    lp.has_irrigation,
    c.crop_name,
    c.average_yield
FROM Land_Plot lp
LEFT JOIN Crop c ON lp.crop_id = c.crop_id;
GO

SELECT
    w.last_name,
    w.first_name,
    e.equipment_type,
    e.model,
    wes.skill_level,
    wes.experience_years
FROM Worker w
LEFT JOIN Worker_Equipment_Skill wes ON w.worker_id      = wes.worker_id
LEFT JOIN Equipment              e   ON wes.equipment_id = e.equipment_id;
GO

SELECT
    c.crop_name,
    c.average_yield,
    lp.plot_id,
    lp.area
FROM Land_Plot lp
RIGHT JOIN Crop c ON lp.crop_id = c.crop_id;
GO

SELECT
    b.brigade_id,
    b.foreman_first_name + ' ' + b.foreman_last_name AS brigadier,
    lp.plot_id,
    lp.area
FROM Brigade b
FULL JOIN Land_Plot lp ON b.brigade_id = lp.brigade_id;
GO

SELECT
    lp.plot_id,
    lp.area,
    lp.soil_quality_index
FROM Land_Plot lp
LEFT JOIN Crop c ON lp.crop_id = c.crop_id
WHERE c.crop_id IS NULL;
GO

SELECT
    b.brigade_id,
    b.foreman_first_name + ' ' + b.foreman_last_name AS brigadier
FROM Brigade b
LEFT JOIN Worker w ON b.brigade_id = w.brigade_id
WHERE w.worker_id IS NULL;
GO

SELECT
    b.brigade_id,
    b.foreman_first_name + ' ' + b.foreman_last_name AS brigadier,
    COUNT(lp.plot_id)  AS plot_count,
    SUM(lp.area)       AS total_area_ha
FROM Brigade b
INNER JOIN Land_Plot lp ON b.brigade_id = lp.brigade_id
GROUP BY b.brigade_id, b.foreman_first_name, b.foreman_last_name
HAVING SUM(lp.area) > 50;
GO

SELECT
    lp.plot_id,
    lp.area,
    c.crop_name,
    COUNT(fa.application_id) AS applications_count,
    SUM(fa.amount_kg)        AS total_amount_kg
FROM Land_Plot lp
INNER JOIN Fertilizer_Application fa ON lp.plot_id = fa.plot_id
INNER JOIN Crop                   c  ON lp.crop_id = c.crop_id
GROUP BY lp.plot_id, lp.area, c.crop_name
HAVING COUNT(fa.application_id) > 1;
GO

SELECT
    e.equipment_type,
    COUNT(wes.skill_id)                                    AS certified_workers,
    AVG(CAST(TRY_CONVERT(DECIMAL(5,2), wes.skill_level) AS DECIMAL(5,2))) AS avg_skill_level,
    MAX(wes.experience_years)                              AS max_experience_years
FROM Equipment e
INNER JOIN Worker_Equipment_Skill wes ON e.equipment_id = wes.equipment_id
GROUP BY e.equipment_type
HAVING AVG(CAST(TRY_CONVERT(DECIMAL(5,2), wes.skill_level) AS DECIMAL(5,2))) >= 3;
GO

SELECT
    b.brigade_id,
    b.foreman_first_name + ' ' + b.foreman_last_name AS brigadier,
    COUNT(DISTINCT w.worker_id)  AS workers_count,
    COUNT(DISTINCT lp.plot_id)   AS plots_count
FROM Brigade b
LEFT JOIN Worker    w  ON b.brigade_id = w.brigade_id
LEFT JOIN Land_Plot lp ON b.brigade_id = lp.brigade_id
GROUP BY b.brigade_id, b.foreman_first_name, b.foreman_last_name
HAVING COUNT(DISTINCT w.worker_id) >= 1;
GO

SELECT
    f.fertilizer_type,
    COUNT(fa.application_id) AS applications_count,
    SUM(fa.amount_kg)        AS total_kg,
    AVG(fa.amount_kg)        AS avg_kg_per_application
FROM Fertilizer f
INNER JOIN Fertilizer_Application fa ON f.fertilizer_id = fa.fertilizer_id
GROUP BY f.fertilizer_type
HAVING SUM(fa.amount_kg) > 10000;
GO

SELECT plot_id, area, soil_quality_index
FROM Land_Plot
WHERE area > 50;
GO

SELECT
    lp.plot_id,
    lp.area,
    c.crop_name,
    c.average_yield
FROM Land_Plot lp
INNER JOIN Crop c ON lp.crop_id = c.crop_id
WHERE c.requires_irrigation = 1;
GO

SELECT
    b.foreman_last_name,
    COUNT(lp.plot_id) AS plot_count,
    SUM(lp.area)      AS total_area
FROM Brigade b
INNER JOIN Land_Plot lp ON b.brigade_id = lp.brigade_id
GROUP BY b.foreman_last_name;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_LandPlot_Area'
      AND object_id = OBJECT_ID('Land_Plot')
)
CREATE NONCLUSTERED INDEX IX_LandPlot_Area ON Land_Plot(area);
GO

SELECT plot_id, area, soil_quality_index
FROM Land_Plot
WHERE area > 50;
GO

SELECT
    lp.plot_id,
    lp.area,
    c.crop_name
FROM Land_Plot lp
INNER JOIN Crop c ON lp.crop_id = c.crop_id
WHERE lp.area > (SELECT AVG(area) FROM Land_Plot);
GO