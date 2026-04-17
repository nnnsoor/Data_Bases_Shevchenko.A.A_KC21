USE Farm_Management_Shevchenko;
GO

SELECT
    fa.application_id,
    fa.application_date,
    fa.amount_kg,
    fa.application_method,
    w.first_name + ' ' + w.last_name AS worker_name,
    f.fertilizer_name,
    lp.area
FROM FERTILIZER_APPLICATION fa
JOIN WORKER w ON fa.worker_id = w.worker_id
JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id
JOIN LAND_PLOT lp ON fa.plot_id = lp.plot_id
WHERE fa.application_date >= '2024-04-01'
ORDER BY fa.application_date DESC;
GO

SELECT
    plot_id,
    area,
    soil_quality_index,
    has_irrigation,
    brigade_id,
    crop_id
FROM LAND_PLOT
WHERE area > 30 AND soil_quality_index >= 8.0
ORDER BY area DESC;
GO

SELECT
    w.worker_id,
    w.first_name + ' ' + w.last_name AS worker_name,
    w.hire_date,
    e.equipment_type,
    e.model,
    wes.skill_level,
    wes.experience_years
FROM WORKER w
JOIN WORKER_EQUIPMENT_SKILL wes ON w.worker_id = wes.worker_id
JOIN EQUIPMENT e ON wes.equipment_id = e.equipment_id
WHERE w.brigade_id = 1
ORDER BY w.last_name, wes.skill_level;
GO

SELECT
    fa.application_date,
    b.foreman_last_name AS brigade_foreman,
    lp.area AS plot_area,
    c.crop_name,
    f.fertilizer_name,
    f.fertilizer_type,
    fa.amount_kg,
    fa.application_method,
    w.first_name + ' ' + w.last_name AS applied_by
FROM FERTILIZER_APPLICATION fa
JOIN BRIGADE b ON fa.brigade_id = b.brigade_id
JOIN LAND_PLOT lp ON fa.plot_id = lp.plot_id
JOIN CROP c ON lp.crop_id = c.crop_id
JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id
JOIN WORKER w ON fa.worker_id = w.worker_id
WHERE fa.application_date BETWEEN '2024-03-01' AND '2024-05-31'
  AND f.fertilizer_type = N'Азотне'
ORDER BY fa.application_date, b.foreman_last_name;
GO

SELECT name 
FROM sys.key_constraints
WHERE type = 'PK' AND parent_object_id = OBJECT_ID('LAND_PLOT');

-- 1. Видаляємо Foreign Key
ALTER TABLE FERTILIZER_APPLICATION 
    DROP CONSTRAINT FK_APPLICATION_PLOT;
GO

-- 2. Видаляємо PK (правильна назва!)
ALTER TABLE LAND_PLOT 
    DROP CONSTRAINT PK__LAND_PLO__D8814F00C4CDC256;
GO

-- 3. Створюємо CLUSTERED індекс
CREATE CLUSTERED INDEX IX_LandPlot_Brigade_Clustered
    ON LAND_PLOT (brigade_id, plot_id);
GO

-- 4. Повертаємо PK як NONCLUSTERED
ALTER TABLE LAND_PLOT
    ADD CONSTRAINT PK_LAND_PLOT PRIMARY KEY NONCLUSTERED (plot_id);
GO

-- 5. Повертаємо Foreign Key
ALTER TABLE FERTILIZER_APPLICATION
    ADD CONSTRAINT FK_APPLICATION_PLOT 
    FOREIGN KEY (plot_id) REFERENCES LAND_PLOT (plot_id);
GO
----

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FertApp_Date' AND object_id = OBJECT_ID('FERTILIZER_APPLICATION'))
    DROP INDEX IX_FertApp_Date ON FERTILIZER_APPLICATION;
CREATE NONCLUSTERED INDEX IX_FertApp_Date
    ON FERTILIZER_APPLICATION (application_date);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Worker_BrigadeId' AND object_id = OBJECT_ID('WORKER'))
    DROP INDEX IX_Worker_BrigadeId ON WORKER;
CREATE NONCLUSTERED INDEX IX_Worker_BrigadeId
    ON WORKER (brigade_id);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LandPlot_Crop_SoilQuality' AND object_id = OBJECT_ID('LAND_PLOT'))
    DROP INDEX IX_LandPlot_Crop_SoilQuality ON LAND_PLOT;
CREATE NONCLUSTERED INDEX IX_LandPlot_Crop_SoilQuality
    ON LAND_PLOT (crop_id, soil_quality_index DESC);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Worker_PhoneNumber_Unique' AND object_id = OBJECT_ID('WORKER'))
    DROP INDEX IX_Worker_PhoneNumber_Unique ON WORKER;
CREATE UNIQUE INDEX IX_Worker_PhoneNumber_Unique
    ON WORKER (phone_number)
    WHERE phone_number IS NOT NULL;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Crop_Name_Unique' AND object_id = OBJECT_ID('CROP'))
    DROP INDEX IX_Crop_Name_Unique ON CROP;
CREATE UNIQUE INDEX IX_Crop_Name_Unique
    ON CROP (crop_name);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FertApp_PlotId_Include' AND object_id = OBJECT_ID('FERTILIZER_APPLICATION'))
    DROP INDEX IX_FertApp_PlotId_Include ON FERTILIZER_APPLICATION;
CREATE NONCLUSTERED INDEX IX_FertApp_PlotId_Include
    ON FERTILIZER_APPLICATION (plot_id)
    INCLUDE (application_date, amount_kg, application_method, fertilizer_id, worker_id);
GO

----

SELECT
    application_date,
    amount_kg,
    application_method,
    worker_id,
    fertilizer_id
FROM FERTILIZER_APPLICATION
WHERE plot_id = 5;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Equipment_Status_Repair' AND object_id = OBJECT_ID('EQUIPMENT'))
    DROP INDEX IX_Equipment_Status_Repair ON EQUIPMENT;
GO

CREATE NONCLUSTERED INDEX IX_Equipment_Status_Repair
    ON EQUIPMENT (equipment_id, equipment_type, model)
    WHERE status = 'Ремонт';
GO

----

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, COLLATION_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'EQUIPMENT' AND COLUMN_NAME = 'status';

CREATE NONCLUSTERED INDEX IX_Equipment_Status_Repair
    ON EQUIPMENT (equipment_id, equipment_type, model)
    WHERE status = N'Ремонт';
GO

SELECT equipment_id, equipment_type, model, brigade_id
FROM EQUIPMENT
WHERE status = N'Ремонт';
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Equipment_Status_Repair' AND object_id = OBJECT_ID('EQUIPMENT'))
    DROP INDEX IX_Equipment_Status_Repair ON EQUIPMENT;
GO

CREATE NONCLUSTERED INDEX IX_Equipment_Status_Repair
    ON EQUIPMENT (equipment_id, equipment_type, model)
    WHERE status = 'Ремонт';
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LandPlot_Irrigated' AND object_id = OBJECT_ID('LAND_PLOT'))
    DROP INDEX IX_LandPlot_Irrigated ON LAND_PLOT;
GO

CREATE NONCLUSTERED INDEX IX_LandPlot_Irrigated
    ON LAND_PLOT (plot_id, area, crop_id)
    WHERE has_irrigation = 1;
GO

SELECT
    OBJECT_NAME(ps.object_id)           AS table_name,
    i.name                              AS index_name,
    i.type_desc                         AS index_type,
    ps.avg_fragmentation_in_percent     AS fragmentation_pct,
    ps.page_count                       AS page_count,
    ps.record_count                     AS record_count
FROM sys.dm_db_index_physical_stats(
    DB_ID(), NULL, NULL, NULL, 'DETAILED') AS ps
JOIN sys.indexes AS i
    ON ps.object_id = i.object_id
   AND ps.index_id  = i.index_id
WHERE i.type > 0
  AND ps.page_count > 0
ORDER BY ps.avg_fragmentation_in_percent DESC;
GO

ALTER INDEX IX_FertApp_Date ON FERTILIZER_APPLICATION REORGANIZE;
GO

ALTER INDEX IX_Worker_BrigadeId ON WORKER REORGANIZE;
GO

ALTER INDEX IX_LandPlot_Crop_SoilQuality ON LAND_PLOT REBUILD;
GO

ALTER INDEX IX_FertApp_PlotId_Include ON FERTILIZER_APPLICATION REBUILD;
GO

ALTER INDEX ALL ON FERTILIZER_APPLICATION REBUILD;
GO

IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE object_id = OBJECT_ID('CROP')
             AND name = 'IX_Crop_Name_Unique')
    DROP INDEX IX_Crop_Name_Unique ON CROP;
GO

ALTER INDEX IX_FertApp_Date ON FERTILIZER_APPLICATION DISABLE;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT fa.application_id, fa.application_date, fa.amount_kg,
       w.last_name, f.fertilizer_name
FROM FERTILIZER_APPLICATION fa
JOIN WORKER w     ON fa.worker_id     = w.worker_id
JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id
WHERE fa.application_date >= '2024-04-01'
ORDER BY fa.application_date;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

ALTER INDEX IX_FertApp_Date ON FERTILIZER_APPLICATION REBUILD;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT fa.application_id, fa.application_date, fa.amount_kg,
       w.last_name, f.fertilizer_name
FROM FERTILIZER_APPLICATION fa
JOIN WORKER w     ON fa.worker_id     = w.worker_id
JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id
WHERE fa.application_date >= '2024-04-01'
ORDER BY fa.application_date;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
----
SELECT
    DB_NAME()                               AS [База_даних],
    OBJECT_NAME(i.[object_id])              AS [Таблиця],
    i.name                                  AS [Індекс],
    i.type_desc                             AS [Тип_індексу],
    CASE WHEN i.is_unique = 1
         THEN 'Так' ELSE 'Ні' END          AS [Унікальний],
    CAST(ps.avg_fragmentation_in_percent
         AS DECIMAL(5,2))                   AS [Фрагментація_%],
    ps.page_count                           AS [Кількість_сторінок],
    ps.record_count                         AS [Кількість_записів]
FROM sys.indexes AS i
INNER JOIN sys.dm_db_index_physical_stats(
    DB_ID(), NULL, NULL, NULL, 'LIMITED') AS ps
    ON i.[object_id] = ps.[object_id]
   AND i.index_id    = ps.index_id
WHERE i.type > 0
  AND i.is_hypothetical = 0
ORDER BY ps.avg_fragmentation_in_percent DESC;
GO