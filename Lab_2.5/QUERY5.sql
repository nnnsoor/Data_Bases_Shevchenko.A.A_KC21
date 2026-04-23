-- ================================================================
-- QUERY.SQL
-- База даних: Farm_Management_Shevchenko
-- Практична робота №7
-- ================================================================

USE Farm_Management_Shevchenko;
GO

-- ================================================================
-- РОЗДІЛ 1: ОСНОВНІ ЗАПИТИ ВАРІАНТА
-- ================================================================

-- Q1: Площа під культури
SELECT
    c.crop_name             AS [Культура],
    COUNT(lp.plot_id)       AS [Кількість ділянок],
    SUM(lp.area)            AS [Загальна площа (га)],
    AVG(lp.area)            AS [Середня площа (га)]
FROM LAND_PLOT lp
JOIN CROP c ON lp.crop_id = c.crop_id
GROUP BY c.crop_name
ORDER BY SUM(lp.area) DESC;
GO

-- Q2: Робітники бригади з технікою (бригада №1)
SELECT
    w.last_name + ' ' + w.first_name AS [ПІБ робітника],
    e.equipment_type                  AS [Тип техніки],
    e.model                           AS [Модель],
    wes.skill_level                   AS [Рівень навички],
    wes.experience_years              AS [Досвід (роки)]
FROM WORKER w
JOIN WORKER_EQUIPMENT_SKILL wes ON w.worker_id = wes.worker_id
JOIN EQUIPMENT e ON wes.equipment_id = e.equipment_id
WHERE w.brigade_id = 1
ORDER BY w.last_name, e.equipment_type;
GO

-- Q3: Культура з максимальною врожайністю
SELECT TOP 1
    crop_name           AS [Культура],
    average_yield       AS [Врожайність (ц/га)],
    growing_season_days AS [Вегетація (дні)],
    CASE requires_irrigation WHEN 1 THEN 'Так' ELSE 'Ні' END AS [Потребує зрошення]
FROM CROP
ORDER BY average_yield DESC;
GO

-- Q4: Бригади з кількістю техніки понад середню
SELECT
    b.brigade_id                                               AS [Бригада],
    b.foreman_last_name + ' ' + b.foreman_first_name          AS [Бригадир],
    COUNT(e.equipment_id)                                      AS [Кількість техніки],
    (SELECT AVG(cnt) FROM
        (SELECT COUNT(*) AS cnt FROM EQUIPMENT GROUP BY brigade_id) t) AS [Середня]
FROM BRIGADE b
JOIN EQUIPMENT e ON b.brigade_id = e.brigade_id
GROUP BY b.brigade_id, b.foreman_last_name, b.foreman_first_name
HAVING COUNT(e.equipment_id) > (
    SELECT AVG(cnt) FROM
        (SELECT COUNT(*) AS cnt FROM EQUIPMENT GROUP BY brigade_id) t
)
ORDER BY COUNT(e.equipment_id) DESC;
GO

-- Q5: Ділянки з невідповідними добривами
-- (культура потребує зрошення, але ділянка без зрошення)
SELECT
    lp.plot_id            AS [ID ділянки],
    c.crop_name           AS [Культура],
    lp.area               AS [Площа (га)],
    b.brigade_id          AS [Бригада]
FROM LAND_PLOT lp
JOIN CROP c ON lp.crop_id = c.crop_id
JOIN BRIGADE b ON lp.brigade_id = b.brigade_id
WHERE c.requires_irrigation = 1 AND lp.has_irrigation = 0
ORDER BY lp.plot_id;
GO


-- ================================================================
-- РОЗДІЛ 2: ІНДЕКСИ (Завдання 3)
-- ================================================================

-- 1. НЕКЛАСТЕРИЗОВАНИЙ індекс на дату внесення добрив
IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name = 'IX_FA_ApplicationDate'
             AND object_id = OBJECT_ID('FERTILIZER_APPLICATION'))
    DROP INDEX IX_FA_ApplicationDate ON FERTILIZER_APPLICATION;
GO
CREATE NONCLUSTERED INDEX IX_FA_ApplicationDate
ON FERTILIZER_APPLICATION (application_date);
GO

-- Тестовий запит (повинен використати IX_FA_ApplicationDate)
SELECT application_id, plot_id, amount_kg
FROM FERTILIZER_APPLICATION
WHERE application_date BETWEEN '2024-03-01' AND '2024-03-31';
GO

-- ----------------------------------------------------------------
-- 2. КЛАСТЕРИЗОВАНИЙ індекс (на тестовій таблиці, бо PK вже кластеризований)

IF OBJECT_ID('LAND_PLOT_DEMO','U') IS NOT NULL DROP TABLE LAND_PLOT_DEMO;
GO
CREATE TABLE LAND_PLOT_DEMO (
    plot_id    INT    NOT NULL,
    brigade_id INT    NOT NULL,
    area       DECIMAL(10,2),
    crop_id    INT
);
CREATE CLUSTERED INDEX IX_LPDEMO_Clustered
    ON LAND_PLOT_DEMO (brigade_id, plot_id);
GO
INSERT INTO LAND_PLOT_DEMO SELECT plot_id, brigade_id, area, crop_id FROM LAND_PLOT;
GO
-- Тест (рядки повертаються відсортовані фізично за brigade_id, plot_id)
SELECT * FROM LAND_PLOT_DEMO WHERE brigade_id = 1 ORDER BY plot_id;
GO
DROP TABLE LAND_PLOT_DEMO;
GO

-- ----------------------------------------------------------------
-- 3. УНІКАЛЬНИЙ індекс (гарантує унікальність телефону)
IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name = 'UX_Worker_Phone'
             AND object_id = OBJECT_ID('WORKER'))
    DROP INDEX UX_Worker_Phone ON WORKER;
GO
CREATE UNIQUE NONCLUSTERED INDEX UX_Worker_Phone
ON WORKER (phone_number)
WHERE phone_number IS NOT NULL;
GO

-- Тест: дублікат повинен дати помилку
-- INSERT INTO WORKER VALUES (999,'Тест','Тест',NULL,'2024-01-01','+380501234567',1);
-- Очікуваний результат: Cannot insert duplicate key row...

-- ----------------------------------------------------------------
-- 4. ІНДЕКС З ВКЛЮЧЕНИМИ СТОВПЦЯМИ (covering index)
IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name = 'IX_FA_PlotDate_Include'
             AND object_id = OBJECT_ID('FERTILIZER_APPLICATION'))
    DROP INDEX IX_FA_PlotDate_Include ON FERTILIZER_APPLICATION;
GO
CREATE NONCLUSTERED INDEX IX_FA_PlotDate_Include
ON FERTILIZER_APPLICATION (plot_id, application_date)
INCLUDE (amount_kg, application_method);
GO

-- Тест (запит повністю покривається індексом — без key lookup)
SELECT plot_id, application_date, amount_kg, application_method
FROM FERTILIZER_APPLICATION
WHERE plot_id = 1
ORDER BY application_date;
GO

-- ----------------------------------------------------------------
-- 5. ФІЛЬТРОВАНИЙ індекс (тільки активна техніка)
IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name = 'IX_Equipment_Active'
             AND object_id = OBJECT_ID('EQUIPMENT'))
    DROP INDEX IX_Equipment_Active ON EQUIPMENT;
GO
CREATE NONCLUSTERED INDEX IX_Equipment_Active
ON EQUIPMENT (brigade_id, equipment_type)
WHERE status = 'Активний';
GO

-- Тест (повинен використати фільтрований індекс)
SELECT brigade_id, equipment_type, model
FROM EQUIPMENT
WHERE status = 'Активний' AND brigade_id = 3
ORDER BY equipment_type;
GO


-- ================================================================
-- РОЗДІЛ 3: ВИМІР ПРОДУКТИВНОСТІ (Завдання 3 + 4)
-- Запусти ПЕРЕД і ПІСЛЯ індексів, порівняй logical reads у Messages
-- ================================================================

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Вимірювання 1: пошук по даті (тест для IX_FA_ApplicationDate)
SELECT application_id, plot_id, amount_kg
FROM FERTILIZER_APPLICATION
WHERE application_date BETWEEN '2024-03-01' AND '2024-03-31';
GO

-- Вимірювання 2: covering index (тест для IX_FA_PlotDate_Include)
SELECT plot_id, application_date, amount_kg, application_method
FROM FERTILIZER_APPLICATION
WHERE plot_id = 1
ORDER BY application_date;
GO

-- Вимірювання 3: фільтрований індекс
SELECT brigade_id, equipment_type, model
FROM EQUIPMENT
WHERE status = 'Активний' AND brigade_id = 3;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- ================================================================
-- РОЗДІЛ 4: АУДИТ ІНДЕКСІВ (Завдання 5)
-- ================================================================

SELECT
    i.name                 AS [Ім я індексу],
    CASE i.type
        WHEN 1 THEN 'Кластеризований'
        WHEN 2 THEN 'Некластеризований'
        ELSE        'Інший'
    END                    AS [Тип],
    CASE i.is_unique
        WHEN 1 THEN 'Так'
        ELSE        'Ні'
    END                    AS [Унікальний],
    CAST(ips.avg_fragmentation_in_percent AS DECIMAL(5,2)) AS [Фрагментація %],
    OBJECT_NAME(i.object_id) AS [Таблиця],
    ips.page_count            AS [Сторінок]
FROM sys.indexes i
JOIN sys.dm_db_index_physical_stats(
        DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    ON i.object_id = ips.object_id
    AND i.index_id = ips.index_id
WHERE OBJECT_NAME(i.object_id) NOT LIKE 'sys%'
  AND i.name IS NOT NULL
ORDER BY [Таблиця], [Тип];
GO