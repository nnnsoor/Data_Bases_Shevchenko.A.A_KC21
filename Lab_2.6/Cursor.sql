USE Farm_Management_Shevchenko;
GO

-- ============================================================
-- ЗАВДАННЯ 3. Транзакція з умовою ROLLBACK
-- Оновлюємо кількість добрива у внесенні, перевіряємо
-- чи існують ділянки з площею понад 100 га.
-- Якщо таких немає – відкочуємо транзакцію.
-- ============================================================
PRINT '=== ЗАВДАННЯ 3: Транзакція з умовою ROLLBACK ===';

BEGIN TRAN;

UPDATE FERTILIZER_APPLICATION
SET amount_kg = amount_kg * 1.10
WHERE application_id = 1;

IF (SELECT COUNT(*) FROM LAND_PLOT WHERE area > 100) = 0
BEGIN
    ROLLBACK;
    PRINT 'ROLLBACK: Ділянок з площею понад 100 га не знайдено. Транзакцію скасовано.';
END
ELSE
BEGIN
    COMMIT;
    PRINT 'COMMIT: Транзакцію підтверджено.';
END
GO

-- ============================================================
-- ЗАВДАННЯ 4. Перевірка @@ERROR для керування транзакцією
-- Спроба оновити запис із неіснуючим worker_id → порушення FK
-- ============================================================
PRINT '=== ЗАВДАННЯ 4: Перевірка @@ERROR ===';

BEGIN TRAN;

UPDATE FERTILIZER_APPLICATION
SET worker_id = 99999          -- неіснуючий worker_id, FK порушення
WHERE application_id = 1;

IF @@ERROR <> 0
BEGIN
    ROLLBACK;
    PRINT 'ROLLBACK: Виявлено помилку (@@ERROR <> 0). Транзакцію скасовано.';
END
ELSE
BEGIN
    COMMIT;
    PRINT 'COMMIT: Транзакцію підтверджено.';
END
GO

-- ============================================================
-- ЗАВДАННЯ 5. TRY...CATCH у транзакціях
-- Спроба вставити запис із дублікатом PRIMARY KEY → помилка → ROLLBACK
-- ============================================================
PRINT '=== ЗАВДАННЯ 5: TRY...CATCH у транзакції ===';

BEGIN TRAN;
BEGIN TRY
    -- Вставляємо запис із вже існуючим application_id=1 → дублікат PK
    INSERT INTO FERTILIZER_APPLICATION
        (application_id, plot_id, fertilizer_id, worker_id, brigade_id,
         application_date, amount_kg, application_method, notes)
    VALUES
        (1, 1, 1, 1, 1, '2024-06-01', 50.00, 'Розсів', 'Дублікат – тест TRY/CATCH');

    COMMIT;
    PRINT 'COMMIT: Транзакцію підтверджено.';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ROLLBACK виконано у блоці CATCH.';
    PRINT 'Повідомлення про помилку: ' + ERROR_MESSAGE();
    PRINT 'Номер помилки: '             + CAST(ERROR_NUMBER()   AS VARCHAR(10));
    PRINT 'Рядок помилки: '             + CAST(ERROR_LINE()     AS VARCHAR(10));
END CATCH;
GO

-- ============================================================
-- ЗАВДАННЯ 6. Транзакція з додаванням 10 000 рядків
-- Створюємо допоміжну таблицю FERTILIZER_LOG та заповнюємо
-- її записами через цикл WHILE у рамках однієї транзакції.
-- ============================================================
PRINT '=== ЗАВДАННЯ 6: Масова вставка 10 000 рядків ===';

-- Створення таблиці-журналу (якщо не існує)
IF OBJECT_ID('FERTILIZER_LOG', 'U') IS NOT NULL
    DROP TABLE FERTILIZER_LOG;

CREATE TABLE FERTILIZER_LOG (
    log_id          INT IDENTITY(1,1) PRIMARY KEY,
    plot_id         INT           NOT NULL,
    fertilizer_id   INT           NOT NULL,
    worker_id       INT           NOT NULL,
    log_date        DATE          NOT NULL,
    amount_kg       DECIMAL(10,2) NOT NULL,
    log_note        VARCHAR(200)  NULL
);
GO

BEGIN TRAN;
BEGIN TRY
    DECLARE @i INT = 1;
    DECLARE @max INT = 10000;

    WHILE @i <= @max
    BEGIN
        INSERT INTO FERTILIZER_LOG (plot_id, fertilizer_id, worker_id, log_date, amount_kg, log_note)
        VALUES (
            (@i % 100) + 1,                          -- plot_id 1-100
            (@i % 10)  + 1,                          -- fertilizer_id 1-10
            (@i % 100) + 1,                          -- worker_id 1-100
            DATEADD(DAY, @i % 365, '2024-01-01'),    -- дата в межах 2024 р.
            CAST((@i % 300) + 50 AS DECIMAL(10,2)),  -- 50-349 кг
            'Тестовий запис №' + CAST(@i AS VARCHAR(10))
        );
        SET @i += 1;
    END;

    COMMIT;
    PRINT 'COMMIT: Успішно вставлено ' + CAST(@max AS VARCHAR(10)) + ' рядків у FERTILIZER_LOG.';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ROLLBACK: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Перевірка кількості рядків
SELECT COUNT(*) AS total_rows FROM FERTILIZER_LOG;
GO

-- ============================================================
-- ЗАВДАННЯ 7. Транзакція з модифікацією процедури
-- Додаємо до процедури виведення часових міток початку/кінця
-- ============================================================
PRINT '=== ЗАВДАННЯ 7: Модифікація процедури з часовими мітками ===';

-- Спочатку створимо базову процедуру (якщо ще немає)
IF OBJECT_ID('usp_GetBrigadeSummary', 'P') IS NOT NULL
    DROP PROCEDURE usp_GetBrigadeSummary;
GO

-- Оновлена процедура з часовими мітками (у транзакції)
BEGIN TRAN;
BEGIN TRY
    EXEC('
    CREATE PROCEDURE usp_GetBrigadeSummary
        @brigade_id INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        -- Часова мітка початку
        DECLARE @start_time DATETIME2 = SYSDATETIME();
        PRINT ''[START] usp_GetBrigadeSummary  '' + CONVERT(VARCHAR(30), @start_time, 121);

        -- Основна логіка: зведення по бригаді
        SELECT
            b.brigade_id,
            b.foreman_last_name + '' '' + b.foreman_first_name AS foreman_name,
            COUNT(DISTINCT w.worker_id)   AS total_workers,
            COUNT(DISTINCT e.equipment_id) AS total_equipment,
            COUNT(DISTINCT lp.plot_id)    AS total_plots,
            ROUND(SUM(lp.area), 2)        AS total_area_ha
        FROM BRIGADE b
        LEFT JOIN WORKER    w  ON w.brigade_id  = b.brigade_id
        LEFT JOIN EQUIPMENT e  ON e.brigade_id  = b.brigade_id
        LEFT JOIN LAND_PLOT lp ON lp.brigade_id = b.brigade_id
        WHERE (@brigade_id IS NULL OR b.brigade_id = @brigade_id)
        GROUP BY b.brigade_id, b.foreman_last_name, b.foreman_first_name
        ORDER BY b.brigade_id;

        -- Часова мітка завершення + тривалість
        DECLARE @end_time DATETIME2 = SYSDATETIME();
        PRINT ''[END]   usp_GetBrigadeSummary  '' + CONVERT(VARCHAR(30), @end_time, 121);
        PRINT ''[TIME]  Тривалість: ''
              + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR(10))
              + '' мс'';
    END;
    ');

    COMMIT;
    PRINT 'COMMIT: Процедуру usp_GetBrigadeSummary створено/оновлено з часовими мітками.';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ROLLBACK: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Виконання процедури для перевірки
EXEC usp_GetBrigadeSummary;
GO
EXEC usp_GetBrigadeSummary @brigade_id = 1;
GO

-- ============================================================
-- ЗАВДАННЯ 8. Складний запит (baseline – без індексу)
-- JOIN: FERTILIZER_APPLICATION + LAND_PLOT + CROP + FERTILIZER + WORKER + BRIGADE
-- Фільтр: тільки бригади з більш ніж 2 внесеннями
-- Сортування: за загальною кількістю кг DESC
-- ============================================================
PRINT '=== ЗАВДАННЯ 8: Складний запит (без додаткового індексу) ===';

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT
    b.brigade_id,
    b.foreman_last_name + ' ' + b.foreman_first_name   AS foreman_name,
    c.crop_name,
    f.fertilizer_name,
    f.fertilizer_type,
    COUNT(fa.application_id)                            AS applications_count,
    ROUND(SUM(fa.amount_kg), 2)                         AS total_kg,
    ROUND(AVG(fa.amount_kg), 2)                         AS avg_kg,
    MIN(fa.application_date)                            AS first_application,
    MAX(fa.application_date)                            AS last_application,
    COUNT(DISTINCT w.worker_id)                         AS unique_workers,
    ROUND(SUM(lp.area), 2)                              AS total_plot_area
FROM FERTILIZER_APPLICATION fa
JOIN LAND_PLOT    lp ON lp.plot_id       = fa.plot_id
JOIN CROP         c  ON c.crop_id        = lp.crop_id
JOIN FERTILIZER   f  ON f.fertilizer_id  = fa.fertilizer_id
JOIN WORKER       w  ON w.worker_id      = fa.worker_id
JOIN BRIGADE      b  ON b.brigade_id     = fa.brigade_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2024-12-31'
  AND lp.soil_quality_index > 7.0
GROUP BY b.brigade_id, b.foreman_last_name, b.foreman_first_name,
         c.crop_name, f.fertilizer_name, f.fertilizer_type
HAVING COUNT(fa.application_id) > 1
ORDER BY total_kg DESC, b.brigade_id, c.crop_name;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ============================================================
-- ЗАВДАННЯ 9. Той самий запит з індексом (оптимізований)
-- ============================================================
PRINT '=== ЗАВДАННЯ 9: Складний запит з індексом ===';

-- Додаємо складений індекс по полях, що використовуються у WHERE / JOIN
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FA_Date_Plot_Brigade' AND object_id = OBJECT_ID('FERTILIZER_APPLICATION'))
    DROP INDEX IX_FA_Date_Plot_Brigade ON FERTILIZER_APPLICATION;

CREATE NONCLUSTERED INDEX IX_FA_Date_Plot_Brigade
ON FERTILIZER_APPLICATION (application_date, plot_id, brigade_id, fertilizer_id, worker_id)
INCLUDE (amount_kg, application_id);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LP_PlotId_SoilCrop' AND object_id = OBJECT_ID('LAND_PLOT'))
    DROP INDEX IX_LP_PlotId_SoilCrop ON LAND_PLOT;

CREATE NONCLUSTERED INDEX IX_LP_PlotId_SoilCrop
ON LAND_PLOT (plot_id, soil_quality_index)
INCLUDE (crop_id, area, brigade_id);
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Той самий запит – тепер з індексом
SELECT
    b.brigade_id,
    b.foreman_last_name + ' ' + b.foreman_first_name   AS foreman_name,
    c.crop_name,
    f.fertilizer_name,
    f.fertilizer_type,
    COUNT(fa.application_id)                            AS applications_count,
    ROUND(SUM(fa.amount_kg), 2)                         AS total_kg,
    ROUND(AVG(fa.amount_kg), 2)                         AS avg_kg,
    MIN(fa.application_date)                            AS first_application,
    MAX(fa.application_date)                            AS last_application,
    COUNT(DISTINCT w.worker_id)                         AS unique_workers,
    ROUND(SUM(lp.area), 2)                              AS total_plot_area
FROM FERTILIZER_APPLICATION fa
JOIN LAND_PLOT    lp ON lp.plot_id       = fa.plot_id
JOIN CROP         c  ON c.crop_id        = lp.crop_id
JOIN FERTILIZER   f  ON f.fertilizer_id  = fa.fertilizer_id
JOIN WORKER       w  ON w.worker_id      = fa.worker_id
JOIN BRIGADE      b  ON b.brigade_id     = fa.brigade_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2024-12-31'
  AND lp.soil_quality_index > 7.0
GROUP BY b.brigade_id, b.foreman_last_name, b.foreman_first_name,
         c.crop_name, f.fertilizer_name, f.fertilizer_type
HAVING COUNT(fa.application_id) > 1
ORDER BY total_kg DESC, b.brigade_id, c.crop_name;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ============================================================
-- ЗАВДАННЯ 10. Cursor 1 – реалізація запиту засобами курсора
-- ============================================================
PRINT '=== ЗАВДАННЯ 10: Cursor 1 – той самий запит через курсор ===';

SET STATISTICS TIME ON;

DECLARE
    @cur_brigade_id   INT,
    @cur_foreman      NVARCHAR(120),
    @cur_crop         NVARCHAR(100),
    @cur_fertilizer   NVARCHAR(100),
    @cur_fert_type    NVARCHAR(50),
    @cur_app_count    INT,
    @cur_total_kg     DECIMAL(10,2),
    @cur_avg_kg       DECIMAL(10,2),
    @cur_first_date   DATE,
    @cur_last_date    DATE,
    @cur_workers      INT,
    @cur_area         DECIMAL(10,2);

-- Таблиця-результат для курсора
IF OBJECT_ID('tempdb..#CursorResult1') IS NOT NULL DROP TABLE #CursorResult1;
CREATE TABLE #CursorResult1 (
    brigade_id        INT,
    foreman_name      NVARCHAR(120),
    crop_name         NVARCHAR(100),
    fertilizer_name   NVARCHAR(100),
    fertilizer_type   NVARCHAR(50),
    applications_count INT,
    total_kg          DECIMAL(10,2),
    avg_kg            DECIMAL(10,2),
    first_application DATE,
    last_application  DATE,
    unique_workers    INT,
    total_plot_area   DECIMAL(10,2)
);

DECLARE cursor1 CURSOR FORWARD_ONLY READ_ONLY FOR
    SELECT
        b.brigade_id,
        b.foreman_last_name + ' ' + b.foreman_first_name,
        c.crop_name,
        f.fertilizer_name,
        f.fertilizer_type,
        COUNT(fa.application_id),
        ROUND(SUM(fa.amount_kg), 2),
        ROUND(AVG(fa.amount_kg), 2),
        MIN(fa.application_date),
        MAX(fa.application_date),
        COUNT(DISTINCT w.worker_id),
        ROUND(SUM(lp.area), 2)
    FROM FERTILIZER_APPLICATION fa
    JOIN LAND_PLOT    lp ON lp.plot_id      = fa.plot_id
    JOIN CROP         c  ON c.crop_id       = lp.crop_id
    JOIN FERTILIZER   f  ON f.fertilizer_id = fa.fertilizer_id
    JOIN WORKER       w  ON w.worker_id     = fa.worker_id
    JOIN BRIGADE      b  ON b.brigade_id    = fa.brigade_id
    WHERE fa.application_date BETWEEN '2024-01-01' AND '2024-12-31'
      AND lp.soil_quality_index > 7.0
    GROUP BY b.brigade_id, b.foreman_last_name, b.foreman_first_name,
             c.crop_name, f.fertilizer_name, f.fertilizer_type
    HAVING COUNT(fa.application_id) > 1
    ORDER BY SUM(fa.amount_kg) DESC, b.brigade_id, c.crop_name;

OPEN cursor1;
FETCH NEXT FROM cursor1 INTO
    @cur_brigade_id, @cur_foreman, @cur_crop, @cur_fertilizer, @cur_fert_type,
    @cur_app_count, @cur_total_kg, @cur_avg_kg, @cur_first_date, @cur_last_date,
    @cur_workers, @cur_area;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #CursorResult1 VALUES (
        @cur_brigade_id, @cur_foreman, @cur_crop, @cur_fertilizer, @cur_fert_type,
        @cur_app_count, @cur_total_kg, @cur_avg_kg, @cur_first_date, @cur_last_date,
        @cur_workers, @cur_area
    );
    FETCH NEXT FROM cursor1 INTO
        @cur_brigade_id, @cur_foreman, @cur_crop, @cur_fertilizer, @cur_fert_type,
        @cur_app_count, @cur_total_kg, @cur_avg_kg, @cur_first_date, @cur_last_date,
        @cur_workers, @cur_area;
END;

CLOSE cursor1;
DEALLOCATE cursor1;

SELECT * FROM #CursorResult1 ORDER BY total_kg DESC;
DROP TABLE #CursorResult1;

SET STATISTICS TIME OFF;
GO

-- ============================================================
-- ЗАВДАННЯ 11. Cursor 2 – запит двічі БЕЗ DEALLOCATE між запусками
-- ============================================================
PRINT '=== ЗАВДАННЯ 11: Cursor 2 – запуск двічі без DEALLOCATE ===';

-- Таблиця-результат
IF OBJECT_ID('tempdb..#CursorResult2') IS NOT NULL DROP TABLE #CursorResult2;
CREATE TABLE #CursorResult2 (
    run_number        INT,
    brigade_id        INT,
    foreman_name      NVARCHAR(120),
    crop_name         NVARCHAR(100),
    fertilizer_name   NVARCHAR(100),
    fertilizer_type   NVARCHAR(50),
    applications_count INT,
    total_kg          DECIMAL(10,2),
    avg_kg            DECIMAL(10,2),
    first_application DATE,
    last_application  DATE,
    unique_workers    INT,
    total_plot_area   DECIMAL(10,2)
);

DECLARE
    @c2_brigade_id  INT,
    @c2_foreman     NVARCHAR(120),
    @c2_crop        NVARCHAR(100),
    @c2_fertilizer  NVARCHAR(100),
    @c2_fert_type   NVARCHAR(50),
    @c2_app_count   INT,
    @c2_total_kg    DECIMAL(10,2),
    @c2_avg_kg      DECIMAL(10,2),
    @c2_first_date  DATE,
    @c2_last_date   DATE,
    @c2_workers     INT,
    @c2_area        DECIMAL(10,2),
    @run            INT;

DECLARE cursor2 CURSOR FOR
    SELECT
        b.brigade_id,
        b.foreman_last_name + ' ' + b.foreman_first_name,
        c.crop_name,
        f.fertilizer_name,
        f.fertilizer_type,
        COUNT(fa.application_id),
        ROUND(SUM(fa.amount_kg), 2),
        ROUND(AVG(fa.amount_kg), 2),
        MIN(fa.application_date),
        MAX(fa.application_date),
        COUNT(DISTINCT w.worker_id),
        ROUND(SUM(lp.area), 2)
    FROM FERTILIZER_APPLICATION fa
    JOIN LAND_PLOT    lp ON lp.plot_id      = fa.plot_id
    JOIN CROP         c  ON c.crop_id       = lp.crop_id
    JOIN FERTILIZER   f  ON f.fertilizer_id = fa.fertilizer_id
    JOIN WORKER       w  ON w.worker_id     = fa.worker_id
    JOIN BRIGADE      b  ON b.brigade_id    = fa.brigade_id
    WHERE fa.application_date BETWEEN '2024-01-01' AND '2024-12-31'
      AND lp.soil_quality_index > 7.0
    GROUP BY b.brigade_id, b.foreman_last_name, b.foreman_first_name,
             c.crop_name, f.fertilizer_name, f.fertilizer_type
    HAVING COUNT(fa.application_id) > 1
    ORDER BY SUM(fa.amount_kg) DESC, b.brigade_id, c.crop_name;

-- ---- Перший запуск ----
SET @run = 1;
SET STATISTICS TIME ON;

OPEN cursor2;
FETCH NEXT FROM cursor2 INTO
    @c2_brigade_id, @c2_foreman, @c2_crop, @c2_fertilizer, @c2_fert_type,
    @c2_app_count, @c2_total_kg, @c2_avg_kg, @c2_first_date, @c2_last_date,
    @c2_workers, @c2_area;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #CursorResult2 VALUES (
        @run,
        @c2_brigade_id, @c2_foreman, @c2_crop, @c2_fertilizer, @c2_fert_type,
        @c2_app_count, @c2_total_kg, @c2_avg_kg, @c2_first_date, @c2_last_date,
        @c2_workers, @c2_area
    );
    FETCH NEXT FROM cursor2 INTO
        @c2_brigade_id, @c2_foreman, @c2_crop, @c2_fertilizer, @c2_fert_type,
        @c2_app_count, @c2_total_kg, @c2_avg_kg, @c2_first_date, @c2_last_date,
        @c2_workers, @c2_area;
END;

CLOSE cursor2;
-- НЕ DEALLOCATE – перевикористовуємо курсор

SET STATISTICS TIME OFF;
PRINT 'Перший запуск cursor2 завершено. Рядків: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ---- Другий запуск (без DEALLOCATE) ----
SET @run = 2;
SET STATISTICS TIME ON;

OPEN cursor2;  -- відкриваємо знову той самий курсор
FETCH NEXT FROM cursor2 INTO
    @c2_brigade_id, @c2_foreman, @c2_crop, @c2_fertilizer, @c2_fert_type,
    @c2_app_count, @c2_total_kg, @c2_avg_kg, @c2_first_date, @c2_last_date,
    @c2_workers, @c2_area;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #CursorResult2 VALUES (
        @run,
        @c2_brigade_id, @c2_foreman, @c2_crop, @c2_fertilizer, @c2_fert_type,
        @c2_app_count, @c2_total_kg, @c2_avg_kg, @c2_first_date, @c2_last_date,
        @c2_workers, @c2_area
    );
    FETCH NEXT FROM cursor2 INTO
        @c2_brigade_id, @c2_foreman, @c2_crop, @c2_fertilizer, @c2_fert_type,
        @c2_app_count, @c2_total_kg, @c2_avg_kg, @c2_first_date, @c2_last_date,
        @c2_workers, @c2_area;
END;

CLOSE cursor2;
DEALLOCATE cursor2;  -- тепер звільняємо

SET STATISTICS TIME OFF;
PRINT 'Другий запуск cursor2 завершено.';

SELECT * FROM #CursorResult2 ORDER BY run_number, total_kg DESC;
DROP TABLE #CursorResult2;
GO