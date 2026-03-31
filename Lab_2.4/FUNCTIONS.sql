USE Farm_Management_Shevchenko;
GO

IF OBJECT_ID('dbo.fn_GetWorkerFullName', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetWorkerFullName;
GO
CREATE FUNCTION dbo.fn_GetWorkerFullName (@worker_id INT)
RETURNS NVARCHAR(150)
AS
BEGIN
    DECLARE @full_name NVARCHAR(150);
    SELECT @full_name = last_name + N' ' +
                        LEFT(first_name, 1) + N'.' +
                        ISNULL(LEFT(patronymic, 1) + N'.', N'')
    FROM Worker
    WHERE worker_id = @worker_id;
    RETURN ISNULL(@full_name, N'Невідомий');
END;
GO

SELECT worker_id,
       dbo.fn_GetWorkerFullName(worker_id) AS full_name,
       hire_date
FROM Worker;
GO

IF OBJECT_ID('dbo.fn_GetFertilizerDensity', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetFertilizerDensity;
GO
CREATE FUNCTION dbo.fn_GetFertilizerDensity (@application_id INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @density DECIMAL(10,2);
    SELECT @density = fa.amount_kg / lp.area
    FROM Fertilizer_Application fa
    JOIN Land_Plot lp ON lp.plot_id = fa.plot_id
    WHERE fa.application_id = @application_id;
    RETURN ISNULL(@density, 0);
END;
GO

SELECT application_id,
       plot_id,
       amount_kg,
       dbo.fn_GetFertilizerDensity(application_id) AS kg_per_ha
FROM Fertilizer_Application;
GO

IF OBJECT_ID('dbo.fn_GetSoilCategory', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetSoilCategory;
GO
CREATE FUNCTION dbo.fn_GetSoilCategory (@plot_id INT)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @idx DECIMAL(5,2);
    DECLARE @cat NVARCHAR(20);
    SELECT @idx = soil_quality_index FROM Land_Plot WHERE plot_id = @plot_id;
    SET @cat = CASE
        WHEN @idx >= 8.0 THEN N'Відмінна'
        WHEN @idx >= 6.0 THEN N'Добра'
        WHEN @idx >= 4.0 THEN N'Задовільна'
        ELSE N'Незадовільна'
    END;
    RETURN ISNULL(@cat, N'Невизначена');
END;
GO

SELECT plot_id,
       area,
       soil_quality_index,
       dbo.fn_GetSoilCategory(plot_id) AS soil_category
FROM Land_Plot;
GO

IF OBJECT_ID('dbo.fn_GetBrigadeWorkers', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetBrigadeWorkers;
GO
CREATE FUNCTION dbo.fn_GetBrigadeWorkers (@brigade_id INT)
RETURNS TABLE
AS
RETURN (
    SELECT w.worker_id,
           w.last_name,
           w.first_name,
           w.patronymic,
           w.hire_date,
           w.phone_number
    FROM Worker w
    WHERE w.brigade_id = @brigade_id
);
GO

SELECT * FROM dbo.fn_GetBrigadeWorkers(1);
GO

IF OBJECT_ID('dbo.fn_GetPlotFertilizers', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetPlotFertilizers;
GO
CREATE FUNCTION dbo.fn_GetPlotFertilizers (@plot_id INT)
RETURNS TABLE
AS
RETURN (
    SELECT fa.application_id,
           f.fertilizer_name,
           f.fertilizer_type,
           fa.application_date,
           fa.amount_kg,
           fa.application_method,
           dbo.fn_GetWorkerFullName(fa.worker_id) AS applied_by
    FROM Fertilizer_Application fa
    JOIN Fertilizer f ON f.fertilizer_id = fa.fertilizer_id
    WHERE fa.plot_id = @plot_id
);
GO

SELECT * FROM dbo.fn_GetPlotFertilizers(1);
GO

IF OBJECT_ID('dbo.fn_GetWorkerEquipment', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetWorkerEquipment;
GO
CREATE FUNCTION dbo.fn_GetWorkerEquipment (@worker_id INT)
RETURNS TABLE
AS
RETURN (
    SELECT e.equipment_id,
           e.equipment_type,
           e.model,
           e.manufacture_year,
           e.status,
           wes.skill_level,
           wes.experience_years,
           wes.certification_date
    FROM Worker_Equipment_Skill wes
    JOIN Equipment e ON e.equipment_id = wes.equipment_id
    WHERE wes.worker_id = @worker_id
);
GO

SELECT * FROM dbo.fn_GetWorkerEquipment(1);
GO

IF OBJECT_ID('dbo.fn_GetBrigadeStatistics', 'TF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetBrigadeStatistics;
GO
CREATE FUNCTION dbo.fn_GetBrigadeStatistics ()
RETURNS @result TABLE (
    brigade_id       INT,
    foreman_name     NVARCHAR(150),
    worker_count     INT,
    plot_count       INT,
    total_area       DECIMAL(10,2),
    equipment_skills INT
)
AS
BEGIN
    INSERT INTO @result
    SELECT
        b.brigade_id,
        b.foreman_last_name + N' ' + LEFT(b.foreman_first_name, 1) + N'.' +
            ISNULL(LEFT(b.foreman_patronymic, 1) + N'.', N'') AS foreman_name,
        (SELECT COUNT(*) FROM Worker w
         WHERE w.brigade_id = b.brigade_id)                    AS worker_count,
        (SELECT COUNT(*) FROM Land_Plot lp
         WHERE lp.brigade_id = b.brigade_id)                   AS plot_count,
        (SELECT ISNULL(SUM(lp.area), 0) FROM Land_Plot lp
         WHERE lp.brigade_id = b.brigade_id)                   AS total_area,
        (SELECT COUNT(*) FROM Worker_Equipment_Skill wes
         JOIN Worker w ON w.worker_id = wes.worker_id
         WHERE w.brigade_id = b.brigade_id)                    AS equipment_skills
    FROM Brigade b;
    RETURN;
END;
GO

SELECT * FROM dbo.fn_GetBrigadeStatistics();
GO

IF OBJECT_ID('dbo.fn_CropAreaDetail', 'TF') IS NOT NULL
    DROP FUNCTION dbo.fn_CropAreaDetail;
GO
CREATE FUNCTION dbo.fn_CropAreaDetail ()
RETURNS @result TABLE (
    crop_name           NVARCHAR(100),
    requires_irrigation BIT,
    plot_id             INT,
    area                DECIMAL(10,2),
    has_irrigation      BIT,
    brigade_id          INT
)
AS
BEGIN
    INSERT INTO @result
    SELECT c.crop_name,
           c.requires_irrigation,
           lp.plot_id,
           lp.area,
           lp.has_irrigation,
           lp.brigade_id
    FROM Land_Plot lp
    JOIN Crop c ON c.crop_id = lp.crop_id;
    RETURN;
END;
GO

SELECT crop_name,
       SUM(area)      AS total_area,
       COUNT(plot_id) AS plot_count
FROM dbo.fn_CropAreaDetail()
GROUP BY crop_name;
GO

IF OBJECT_ID('dbo.fn_FertilizerApplicationReport', 'TF') IS NOT NULL
    DROP FUNCTION dbo.fn_FertilizerApplicationReport;
GO
CREATE FUNCTION dbo.fn_FertilizerApplicationReport ()
RETURNS @result TABLE (
    application_id   INT,
    plot_id          INT,
    crop_name        NVARCHAR(100),
    fertilizer_name  NVARCHAR(100),
    fertilizer_type  NVARCHAR(50),
    amount_kg        DECIMAL(10,2),
    area             DECIMAL(10,2),
    density_kg_ha    DECIMAL(10,2),
    recommended_rate DECIMAL(10,2),
    status           NVARCHAR(30)
)
AS
BEGIN
    INSERT INTO @result
    SELECT
        fa.application_id,
        fa.plot_id,
        ISNULL(c.crop_name, N'Не вказано'),
        f.fertilizer_name,
        f.fertilizer_type,
        fa.amount_kg,
        lp.area,
        ROUND(fa.amount_kg / lp.area, 2),
        f.application_rate,
        CASE
            WHEN f.application_rate IS NULL           THEN N'Норма не задана'
            WHEN fa.amount_kg / lp.area > f.application_rate
                                                      THEN N'Перевищення норми'
            WHEN fa.amount_kg / lp.area < f.application_rate * 0.7
                                                      THEN N'Недостатньо'
            ELSE N'В нормі'
        END
    FROM Fertilizer_Application fa
    JOIN Land_Plot lp ON lp.plot_id = fa.plot_id
    JOIN Fertilizer f  ON f.fertilizer_id = fa.fertilizer_id
    LEFT JOIN Crop c   ON c.crop_id = lp.crop_id;
    RETURN;
END;
GO

SELECT * FROM dbo.fn_FertilizerApplicationReport();
GO

IF OBJECT_ID('dbo.fn_AreaByCrop', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_AreaByCrop;
GO
CREATE FUNCTION dbo.fn_AreaByCrop ()
RETURNS TABLE
AS
RETURN (
    SELECT c.crop_id,
           c.crop_name,
           c.requires_irrigation,
           COUNT(lp.plot_id)            AS plot_count,
           SUM(lp.area)                 AS total_area_ha,
           AVG(lp.soil_quality_index)   AS avg_soil_quality
    FROM Crop c
    LEFT JOIN Land_Plot lp ON lp.crop_id = c.crop_id
    GROUP BY c.crop_id, c.crop_name, c.requires_irrigation
);
GO

SELECT * FROM dbo.fn_AreaByCrop()
ORDER BY total_area_ha DESC;
GO

IF OBJECT_ID('dbo.fn_BrigadeWorkersWithEquipment', 'TF') IS NOT NULL
    DROP FUNCTION dbo.fn_BrigadeWorkersWithEquipment;
GO
CREATE FUNCTION dbo.fn_BrigadeWorkersWithEquipment (@brigade_id INT)
RETURNS @result TABLE (
    brigade_id     INT,
    worker_id      INT,
    worker_name    NVARCHAR(150),
    equipment_type NVARCHAR(100),
    model          NVARCHAR(100),
    skill_level    NVARCHAR(50),   
    eq_status      NVARCHAR(50)
)
AS
BEGIN
    INSERT INTO @result
    SELECT b.brigade_id,
           w.worker_id,
           dbo.fn_GetWorkerFullName(w.worker_id),
           NULL, NULL, NULL, NULL
    FROM Worker w
    JOIN Brigade b ON b.brigade_id = w.brigade_id
    WHERE w.brigade_id = @brigade_id
      AND NOT EXISTS (
          SELECT 1 FROM Worker_Equipment_Skill wes
          WHERE wes.worker_id = w.worker_id
      );

    INSERT INTO @result
    SELECT b.brigade_id,
           w.worker_id,
           dbo.fn_GetWorkerFullName(w.worker_id),
           e.equipment_type,
           e.model,
           CAST(wes.skill_level AS NVARCHAR(50)),
           e.status
    FROM Worker w
    JOIN Brigade b                  ON b.brigade_id  = w.brigade_id
    JOIN Worker_Equipment_Skill wes ON wes.worker_id = w.worker_id
    JOIN Equipment e                ON e.equipment_id = wes.equipment_id
    WHERE w.brigade_id = @brigade_id;
    RETURN;
END;
GO

SELECT * FROM dbo.fn_BrigadeWorkersWithEquipment(1);
GO

IF OBJECT_ID('dbo.fn_MaxYieldCropName', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_MaxYieldCropName;
GO
CREATE FUNCTION dbo.fn_MaxYieldCropName ()
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @name NVARCHAR(100);
    SELECT TOP 1 @name = crop_name
    FROM Crop
    ORDER BY average_yield DESC;
    RETURN @name;
END;
GO

SELECT dbo.fn_MaxYieldCropName() AS max_yield_crop;
GO

IF OBJECT_ID('dbo.fn_BrigadesAboveAvgEquipmentSkills', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_BrigadesAboveAvgEquipmentSkills;
GO
CREATE FUNCTION dbo.fn_BrigadesAboveAvgEquipmentSkills ()
RETURNS TABLE
AS
RETURN (
    WITH BrigadeSkills AS (
        SELECT b.brigade_id,
               b.foreman_last_name + N' ' +
               LEFT(b.foreman_first_name, 1) + N'.' AS foreman,
               COUNT(wes.skill_id)                  AS skill_count
        FROM Brigade b
        LEFT JOIN Worker w
               ON w.brigade_id = b.brigade_id
        LEFT JOIN Worker_Equipment_Skill wes
               ON wes.worker_id = w.worker_id
        GROUP BY b.brigade_id, b.foreman_last_name, b.foreman_first_name
    )
    SELECT brigade_id,
           foreman,
           skill_count
    FROM BrigadeSkills
    WHERE skill_count > (
        SELECT AVG(CAST(skill_count AS FLOAT)) FROM BrigadeSkills
    )
);
GO

SELECT * FROM dbo.fn_BrigadesAboveAvgEquipmentSkills();
GO

IF OBJECT_ID('dbo.fn_PlotsWithInappropriateFertilizers', 'TF') IS NOT NULL
    DROP FUNCTION dbo.fn_PlotsWithInappropriateFertilizers;
GO
CREATE FUNCTION dbo.fn_PlotsWithInappropriateFertilizers ()
RETURNS @result TABLE (
    plot_id          INT,
    area             DECIMAL(10,2),
    crop_name        NVARCHAR(100),
    fertilizer_name  NVARCHAR(100),
    density_kg_ha    DECIMAL(10,2),
    recommended_rate DECIMAL(10,2),
    excess_percent   DECIMAL(10,2),
    issue            NVARCHAR(100)
)
AS
BEGIN
    INSERT INTO @result
    SELECT lp.plot_id,
           lp.area,
           ISNULL(c.crop_name, N'Не вказано'),
           f.fertilizer_name,
           ROUND(fa.amount_kg / lp.area, 2),
           f.application_rate,
           ROUND(
               (fa.amount_kg / lp.area - f.application_rate)
               / f.application_rate * 100, 1),
           N'Перевищення норми внесення'
    FROM Fertilizer_Application fa
    JOIN Land_Plot lp ON lp.plot_id       = fa.plot_id
    JOIN Fertilizer f  ON f.fertilizer_id = fa.fertilizer_id
    LEFT JOIN Crop c   ON c.crop_id       = lp.crop_id
    WHERE f.application_rate IS NOT NULL
      AND fa.amount_kg / lp.area > f.application_rate;

    INSERT INTO @result
    SELECT lp.plot_id,
           lp.area,
           c.crop_name,
           N'—',
           NULL, NULL, NULL,
           N'Культура потребує зрошення, зрошення відсутнє'
    FROM Land_Plot lp
    JOIN Crop c ON c.crop_id = lp.crop_id
    WHERE c.requires_irrigation = 1
      AND lp.has_irrigation = 0;
    RETURN;
END;
GO

SELECT * FROM dbo.fn_PlotsWithInappropriateFertilizers();
GO

SELECT * FROM dbo.fn_AreaByCrop();
SELECT * FROM dbo.fn_BrigadeWorkersWithEquipment(1);
SELECT * FROM dbo.fn_PlotsWithInappropriateFertilizers();

SET STATISTICS IO, TIME ON;
SELECT * FROM dbo.fn_AreaByCrop();
SET STATISTICS IO, TIME OFF;


SET STATISTICS IO, TIME ON;
SELECT * FROM dbo.fn_PlotsWithInappropriateFertilizers();
SET STATISTICS IO, TIME OFF;
