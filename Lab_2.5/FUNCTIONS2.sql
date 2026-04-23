-- ================================================================
-- FUNCTIONS.SQL
-- База даних: Farm_Management_Shevchenko
-- Завдання 11: Процедура з послідовністю (SEQUENCE) для PK
--
-- ВАЖЛИВО: NEXT VALUE FOR не може використовуватись у скалярних
-- функціях (обмеження T-SQL). Тому реалізуємо через процедуру
-- з OUTPUT-параметром, що еквівалентно завданню:
-- "повертає PK вставленого запису або NULL".
-- ================================================================

USE Farm_Management_Shevchenko;
GO

-- ================================================================
-- КРОК 1: Створити SEQUENCE для генерації PK
-- ================================================================

IF OBJECT_ID('seq_application_id', 'SO') IS NOT NULL
    DROP SEQUENCE seq_application_id;
GO

CREATE SEQUENCE seq_application_id
    START WITH 10001
    INCREMENT BY 1
    MINVALUE 1
    NO MAXVALUE
    NO CYCLE
    CACHE 10;
GO

-- Перевірка: побачити перше значення послідовності
SELECT NEXT VALUE FOR seq_application_id AS [Перший PK з послідовності];
GO

-- ================================================================
-- КРОК 2: Допоміжна скалярна функція (без INSERT/SEQUENCE)
-- Перевіряє чи існує запис з таким application_id
-- (функція без INSERT — дозволено T-SQL)
-- ================================================================

CREATE OR ALTER FUNCTION dbo.fn_ApplicationExists(
    @application_id INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @result BIT = 0;
    IF EXISTS (SELECT 1 FROM FERTILIZER_APPLICATION
               WHERE application_id = @application_id)
        SET @result = 1;
    RETURN @result;
END;
GO

-- Тест функції:
SELECT dbo.fn_ApplicationExists(1)  AS [Запис 1 існує],   -- очікується 1
       dbo.fn_ApplicationExists(9999) AS [Запис 9999 існує]; -- очікується 0
GO

-- ================================================================
-- КРОК 3: Процедура usp_InsertApplicationWithSequence
-- Отримує новий PK з послідовності, вставляє запис,
-- повертає PK через OUTPUT або NULL при помилці
-- ================================================================

CREATE OR ALTER PROCEDURE dbo.usp_InsertApplicationWithSequence
    @plot_id            INT,
    @fertilizer_id      INT,
    @worker_id          INT,
    @brigade_id         INT,
    @application_date   DATE,
    @amount_kg          DECIMAL(10,2),
    @application_method VARCHAR(50) = NULL,
    @notes              VARCHAR(500) = NULL,
    @inserted_id        INT OUTPUT          -- повертає новий PK або NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @inserted_id = NULL;

    -- Отримуємо новий PK з послідовності
    DECLARE @new_id INT;
    SET @new_id = NEXT VALUE FOR seq_application_id;

    BEGIN TRY
        INSERT INTO FERTILIZER_APPLICATION
            (application_id, plot_id, fertilizer_id, worker_id,
             brigade_id, application_date, amount_kg,
             application_method, notes)
        VALUES
            (@new_id, @plot_id, @fertilizer_id, @worker_id,
             @brigade_id, @application_date, @amount_kg,
             @application_method, @notes);

        -- Вставка успішна — повертаємо ключ
        SET @inserted_id = @new_id;
        PRINT N'Запис вставлено. Новий PK = ' + CAST(@new_id AS VARCHAR);
    END TRY
    BEGIN CATCH
        -- Помилка (FK порушення тощо) — @inserted_id залишається NULL
        SET @inserted_id = NULL;
        PRINT N'Помилка вставки: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- ================================================================
-- КРОК 4: Тестування процедури
-- ================================================================

-- Тест 1: успішна вставка
DECLARE @pk INT;
EXEC dbo.usp_InsertApplicationWithSequence
    @plot_id            = 1,
    @fertilizer_id      = 1,
    @worker_id          = 1,
    @brigade_id         = 1,
    @application_date   = '2024-06-01',
    @amount_kg          = 200.00,
    @application_method = N'Розсів',
    @notes              = N'Тестовий запис через процедуру з SEQUENCE',
    @inserted_id        = @pk OUTPUT;

SELECT @pk AS [Вставлений PK];  -- очікується 10002 або більше
GO

-- Тест 2: перевіряємо що запис реально з'явився
SELECT application_id, plot_id, fertilizer_id,
       application_date, amount_kg, notes
FROM FERTILIZER_APPLICATION
WHERE application_id >= 10001
ORDER BY application_id;
GO

-- Тест 3: помилка — неіснуючий plot_id (FK порушення → NULL)
DECLARE @pk2 INT;
EXEC dbo.usp_InsertApplicationWithSequence
    @plot_id            = 9999,   -- не існує → FK constraint fail
    @fertilizer_id      = 1,
    @worker_id          = 1,
    @brigade_id         = 1,
    @application_date   = '2024-06-02',
    @amount_kg          = 100.00,
    @application_method = N'Розсів',
    @notes              = NULL,
    @inserted_id        = @pk2 OUTPUT;

SELECT @pk2 AS [PK при помилці FK];  -- очікується NULL
GO

-- Тест 4: перевірка допоміжної функції після вставки
SELECT
    dbo.fn_ApplicationExists(10001) AS [10001 існує],  -- 1
    dbo.fn_ApplicationExists(10002) AS [10002 існує],  -- 1
    dbo.fn_ApplicationExists(9999)  AS [9999 існує];   -- 0
GO