-- ================================================================
-- PROCEDURES.SQL
-- База даних: Farm_Management_Shevchenko
-- Завдання 6,7,8,9,10
-- ================================================================

USE Farm_Management_Shevchenko;
GO


-- ================================================================
-- ЗАВДАННЯ 6: СИСТЕМНІ збережені процедури
-- ================================================================

-- sp_helpindex — показує всі індекси таблиці
-- Використання: переглянути які індекси є на FERTILIZER_APPLICATION
EXEC sp_helpindex 'FERTILIZER_APPLICATION';
GO

-- sp_spaceused — розмір таблиці (рядки, дані, індекси)
-- Використання: скільки місця займає таблиця WORKER
EXEC sp_spaceused 'WORKER';
GO

-- sp_rename — перейменування індексу / об'єкта
-- Використання: перейменувати індекс для читабельності
EXEC sp_rename
    N'FERTILIZER_APPLICATION.IX_FA_ApplicationDate',
    N'IX_FA_Date_Renamed',
    N'INDEX';
GO
-- Повернути назад
EXEC sp_rename
    N'FERTILIZER_APPLICATION.IX_FA_Date_Renamed',
    N'IX_FA_ApplicationDate',
    N'INDEX';
GO


-- ================================================================
-- ЗАВДАННЯ 7: ГЛОБАЛЬНІ тимчасові збережені процедури (##)
-- Видні ВСІМ сесіям. Видаляються при закритті БД / перезапуску.
-- ================================================================

-- ##1: Статистика внесення добрив по бригадах
IF OBJECT_ID('tempdb..##GetBrigadeFertilizerStats') IS NOT NULL
    DROP PROCEDURE ##GetBrigadeFertilizerStats;
GO
CREATE PROCEDURE ##GetBrigadeFertilizerStats AS
BEGIN
    SELECT
        fa.brigade_id                       AS [Бригада],
        COUNT(*)                            AS [Кількість внесень],
        SUM(fa.amount_kg)                   AS [Всього кг],
        CAST(AVG(fa.amount_kg) AS DECIMAL(10,2)) AS [Середньо кг]
    FROM FERTILIZER_APPLICATION fa
    GROUP BY fa.brigade_id
    ORDER BY SUM(fa.amount_kg) DESC;
END;
GO
-- Виклик:
EXEC ##GetBrigadeFertilizerStats;
GO

-- ##2: Топ-5 добрив за кількістю застосувань
IF OBJECT_ID('tempdb..##TopFertilizers') IS NOT NULL
    DROP PROCEDURE ##TopFertilizers;
GO
CREATE PROCEDURE ##TopFertilizers AS
BEGIN
    SELECT TOP 5
        f.fertilizer_name           AS [Добриво],
        f.fertilizer_type           AS [Тип],
        COUNT(*)                    AS [Кількість внесень],
        SUM(fa.amount_kg)           AS [Всього кг]
    FROM FERTILIZER_APPLICATION fa
    JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id
    GROUP BY f.fertilizer_name, f.fertilizer_type
    ORDER BY COUNT(*) DESC;
END;
GO
EXEC ##TopFertilizers;
GO

-- ##3: Ділянки без внесення добрив у поточному році
IF OBJECT_ID('tempdb..##PlotsWithoutFertilizer') IS NOT NULL
    DROP PROCEDURE ##PlotsWithoutFertilizer;
GO
CREATE PROCEDURE ##PlotsWithoutFertilizer AS
BEGIN
    SELECT
        lp.plot_id          AS [ID ділянки],
        c.crop_name         AS [Культура],
        lp.area             AS [Площа (га)],
        lp.brigade_id       AS [Бригада]
    FROM LAND_PLOT lp
    LEFT JOIN CROP c ON lp.crop_id = c.crop_id
    WHERE lp.plot_id NOT IN (
        SELECT DISTINCT plot_id
        FROM FERTILIZER_APPLICATION
        WHERE YEAR(application_date) = YEAR(GETDATE())
    )
    ORDER BY lp.plot_id;
END;
GO
EXEC ##PlotsWithoutFertilizer;
GO


-- ================================================================
-- ЗАВДАННЯ 8: ТИМЧАСОВІ збережені процедури (#)
-- Видні ТІЛЬКИ поточній сесії. Видаляються при закритті сесії.
-- ================================================================

-- #1: Активна техніка конкретної бригади
IF OBJECT_ID('tempdb..#GetActiveBrigadeEquipment') IS NOT NULL
    DROP PROCEDURE #GetActiveBrigadeEquipment;
GO
CREATE PROCEDURE #GetActiveBrigadeEquipment
    @BrigadeID INT
AS
BEGIN
    SELECT
        equipment_type      AS [Тип техніки],
        model               AS [Модель],
        manufacture_year    AS [Рік виробн.],
        status              AS [Статус]
    FROM EQUIPMENT
    WHERE brigade_id = @BrigadeID
      AND status = N'Активний'
    ORDER BY equipment_type;
END;
GO
-- Виклик:
EXEC #GetActiveBrigadeEquipment @BrigadeID = 1;
GO

-- #2: Кількість добрив певного типу за рік
IF OBJECT_ID('tempdb..#CountFertilizerByType') IS NOT NULL
    DROP PROCEDURE #CountFertilizerByType;
GO
CREATE PROCEDURE #CountFertilizerByType
    @FertType NVARCHAR(50),
    @Year     INT
AS
BEGIN
    SELECT
        f.fertilizer_name       AS [Добриво],
        COUNT(*)                AS [Внесень],
        SUM(fa.amount_kg)       AS [Всього кг],
        AVG(fa.amount_kg)       AS [Середньо кг]
    FROM FERTILIZER_APPLICATION fa
    JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id
    WHERE f.fertilizer_type = @FertType
      AND YEAR(fa.application_date) = @Year
    GROUP BY f.fertilizer_name
    ORDER BY SUM(fa.amount_kg) DESC;
END;
GO
-- Виклик:
EXEC #CountFertilizerByType @FertType = N'Азотне', @Year = 2024;
GO

-- #3: Середня площа ділянок бригади
IF OBJECT_ID('tempdb..#AvgPlotAreaByBrigade') IS NOT NULL
    DROP PROCEDURE #AvgPlotAreaByBrigade;
GO
CREATE PROCEDURE #AvgPlotAreaByBrigade
    @BrigadeID INT
AS
BEGIN
    SELECT
        @BrigadeID              AS [Бригада],
        COUNT(*)                AS [Ділянок],
        CAST(AVG(area) AS DECIMAL(10,2)) AS [Середня площа (га)],
        CAST(SUM(area) AS DECIMAL(10,2)) AS [Загальна площа (га)]
    FROM LAND_PLOT
    WHERE brigade_id = @BrigadeID;
END;
GO
-- Виклик:
EXEC #AvgPlotAreaByBrigade @BrigadeID = 3;
GO


-- ================================================================
-- ЗАВДАННЯ 9: ЗБЕРЕЖЕНІ ПРОЦЕДУРИ КОРИСТУВАЧА (з транзакціями)
-- ================================================================

-- usp_1: Оновити бригадира (UPDATE з транзакцією)
CREATE OR ALTER PROCEDURE usp_UpdateForeman
    @BrigadeID     INT,
    @NewFirstName  NVARCHAR(50),
    @NewLastName   NVARCHAR(50),
    @NewPatronymic NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            IF NOT EXISTS (SELECT 1 FROM BRIGADE WHERE brigade_id = @BrigadeID)
                THROW 50001, N'Бригаду не знайдено', 1;

            UPDATE BRIGADE
            SET foreman_first_name = @NewFirstName,
                foreman_last_name  = @NewLastName,
                foreman_patronymic = @NewPatronymic
            WHERE brigade_id = @BrigadeID;

        COMMIT TRANSACTION;
        PRINT N'Бригадира оновлено. BrigadeID=' + CAST(@BrigadeID AS VARCHAR);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT N'Помилка: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO
-- Виклик (тест — оновлюємо бригаду 1 тими самими даними):
EXEC usp_UpdateForeman
    @BrigadeID     = 1,
    @NewFirstName  = N'Іван',
    @NewLastName   = N'Коваленко',
    @NewPatronymic = N'Петрович';
GO

-- Перевірка після оновлення:
SELECT brigade_id, foreman_first_name, foreman_last_name FROM BRIGADE WHERE brigade_id = 1;
GO

-- ----------------------------------------------------------------
-- usp_2: Перенести ділянку до іншої бригади (UPDATE з транзакцією)
CREATE OR ALTER PROCEDURE usp_TransferPlot
    @PlotID       INT,
    @NewBrigadeID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            IF NOT EXISTS (SELECT 1 FROM BRIGADE WHERE brigade_id = @NewBrigadeID)
                THROW 50002, N'Цільова бригада не існує', 1;

            IF NOT EXISTS (SELECT 1 FROM LAND_PLOT WHERE plot_id = @PlotID)
                THROW 50003, N'Ділянку не знайдено', 1;

            UPDATE LAND_PLOT
            SET brigade_id = @NewBrigadeID
            WHERE plot_id = @PlotID;

        COMMIT TRANSACTION;
        PRINT N'Ділянка ' + CAST(@PlotID AS VARCHAR)
            + N' перенесена до бригади ' + CAST(@NewBrigadeID AS VARCHAR);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT N'Помилка: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO
-- Виклик (перенести ділянку 5 до бригади 2):
EXEC usp_TransferPlot @PlotID = 5, @NewBrigadeID = 2;
GO
-- Перевірка:
SELECT plot_id, brigade_id FROM LAND_PLOT WHERE plot_id = 5;
GO
-- Повернути назад:
EXEC usp_TransferPlot @PlotID = 5, @NewBrigadeID = 3;
GO

-- ----------------------------------------------------------------
-- usp_3: Видалити записи внесення добрив за рік (DELETE з транзакцією)
CREATE OR ALTER PROCEDURE usp_DeleteApplicationsByYear
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Count INT;
    BEGIN TRY
        BEGIN TRANSACTION;
            SELECT @Count = COUNT(*) FROM FERTILIZER_APPLICATION
            WHERE YEAR(application_date) = @Year;

            IF @Count = 0
                THROW 50004, N'Немає записів за вказаний рік', 1;

            DELETE FROM FERTILIZER_APPLICATION
            WHERE YEAR(application_date) = @Year;

        COMMIT TRANSACTION;
        PRINT CAST(@Count AS VARCHAR) + N' записів видалено за ' + CAST(@Year AS VARCHAR) + N' рік';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT N'Помилка: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO
-- УВАГА: розкоментуй якщо хочеш протестувати видалення
-- EXEC usp_DeleteApplicationsByYear @Year = 2023;
-- Перевірка:
-- SELECT COUNT(*) FROM FERTILIZER_APPLICATION WHERE YEAR(application_date) = 2023;


-- ================================================================
-- ЗАВДАННЯ 10: Процедура вставки N рядків за параметром
-- ================================================================

CREATE OR ALTER PROCEDURE usp_GenerateApplicationRows
    @RowCount INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i INT = 1;
    DECLARE @MaxID INT;
    SELECT @MaxID = ISNULL(MAX(application_id), 0) FROM FERTILIZER_APPLICATION;

    WHILE @i <= @RowCount
    BEGIN
        INSERT INTO FERTILIZER_APPLICATION
            (application_id, plot_id, fertilizer_id, worker_id,
             brigade_id, application_date, amount_kg, application_method, notes)
        VALUES (
            @MaxID + @i,
            (ABS(CHECKSUM(NEWID())) % 100) + 1,
            (ABS(CHECKSUM(NEWID())) % 10)  + 1,
            (ABS(CHECKSUM(NEWID())) % 100) + 1,
            (ABS(CHECKSUM(NEWID())) % 10)  + 1,
            DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 365), GETDATE()),
            ROUND(50 + RAND() * 300, 2),
            CASE ABS(CHECKSUM(NEWID())) % 3
                WHEN 0 THEN N'Розсів'
                WHEN 1 THEN N'Обприскування'
                ELSE        N'Внесення в грунт'
            END,
            NULL
        );
        SET @i += 1;
    END;
    PRINT CAST(@RowCount AS VARCHAR) + N' рядків додано';
END;
GO

-- ПОРЯДОК ВИКЛИКУ ДЛЯ АНАЛІЗУ (Завдання 4):
-- Крок 1: базові 100 рядків вже є з INSERT.SQL
-- Крок 2: Довести до 500
EXEC usp_GenerateApplicationRows @RowCount = 400;
GO
-- Перевірка:
SELECT COUNT(*) AS [Всього рядків] FROM FERTILIZER_APPLICATION;
GO

-- Крок 3: Довести до 1000
EXEC usp_GenerateApplicationRows @RowCount = 500;
GO
SELECT COUNT(*) AS [Всього рядків] FROM FERTILIZER_APPLICATION;
GO

-- Крок 4: Довести до 10000
EXEC usp_GenerateApplicationRows @RowCount = 9000;
GO
SELECT COUNT(*) AS [Всього рядків] FROM FERTILIZER_APPLICATION;
GO