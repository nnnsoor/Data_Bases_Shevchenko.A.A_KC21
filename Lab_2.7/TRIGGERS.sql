-- ============================================================
-- TRIGGERS.SQL
-- Farm Management System - Farm_Management_Shevchenko
-- Лабораторна робота: DML, DDL та LOGON тригери
-- ============================================================

USE Farm_Management_Shevchenko;
GO

-- ============================================================
-- ЗАВДАННЯ 3: DML ТРИГЕРИ (AFTER та INSTEAD OF)
-- ============================================================

-- -------------------------------------------------------
-- Тригер 1: AFTER INSERT на FERTILIZER_APPLICATION
-- Логує факт нового внесення добрива
-- -------------------------------------------------------
IF OBJECT_ID('trg_AfterInsert_FertApp', 'TR') IS NOT NULL
    DROP TRIGGER trg_AfterInsert_FertApp;
GO

CREATE TRIGGER trg_AfterInsert_FertApp
ON FERTILIZER_APPLICATION
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Новий запис внесення добрива успішно додано:';
    SELECT
        i.application_id,
        i.plot_id,
        i.fertilizer_id,
        i.worker_id,
        i.application_date,
        i.amount_kg,
        i.application_method
    FROM INSERTED i;
END;
GO

-- Тест тригера trg_AfterInsert_FertApp
INSERT INTO FERTILIZER_APPLICATION
    (application_id, plot_id, fertilizer_id, worker_id, brigade_id, application_date, amount_kg, application_method)
VALUES (201, 1, 1, 1, 1, '2024-06-01', 100.00, 'Розсів');
GO


-- -------------------------------------------------------
-- Тригер 2: AFTER UPDATE на LAND_PLOT
-- Логує зміну культури на земельній ділянці
-- -------------------------------------------------------
IF OBJECT_ID('trg_AfterUpdate_LandPlot', 'TR') IS NOT NULL
    DROP TRIGGER trg_AfterUpdate_LandPlot;
GO

CREATE TRIGGER trg_AfterUpdate_LandPlot
ON LAND_PLOT
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(crop_id)
    BEGIN
        PRINT 'Зафіксовано зміну культури на ділянці:';
        SELECT
            d.plot_id,
            d.crop_id  AS old_crop_id,
            i.crop_id  AS new_crop_id,
            GETDATE()  AS changed_at
        FROM DELETED  d
        JOIN INSERTED i ON d.plot_id = i.plot_id
        WHERE d.crop_id <> i.crop_id OR (d.crop_id IS NULL AND i.crop_id IS NOT NULL);
    END
END;
GO

-- Тест тригера trg_AfterUpdate_LandPlot
UPDATE LAND_PLOT SET crop_id = 4 WHERE plot_id = 2;
GO


-- -------------------------------------------------------
-- Тригер 3: AFTER DELETE на FERTILIZER_APPLICATION
-- Логує видалення запису про внесення добрив
-- -------------------------------------------------------
IF OBJECT_ID('trg_AfterDelete_FertApp', 'TR') IS NOT NULL
    DROP TRIGGER trg_AfterDelete_FertApp;
GO

CREATE TRIGGER trg_AfterDelete_FertApp
ON FERTILIZER_APPLICATION
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Видалено запис про внесення добрива:';
    SELECT
        d.application_id,
        d.plot_id,
        d.fertilizer_id,
        d.application_date,
        d.amount_kg
    FROM DELETED d;
END;
GO

-- Тест тригера trg_AfterDelete_FertApp
DELETE FROM FERTILIZER_APPLICATION WHERE application_id = 201;
GO


-- -------------------------------------------------------
-- Тригер 4: INSTEAD OF DELETE на WORKER
-- Забороняє видалення працівника, якщо є записи в FERTILIZER_APPLICATION
-- -------------------------------------------------------
IF OBJECT_ID('trg_InsteadOfDelete_Worker', 'TR') IS NOT NULL
    DROP TRIGGER trg_InsteadOfDelete_Worker;
GO

CREATE TRIGGER trg_InsteadOfDelete_Worker
ON WORKER
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Перевіряємо, чи є у цього працівника записи внесення добрив
    IF EXISTS (
        SELECT 1
        FROM FERTILIZER_APPLICATION fa
        JOIN DELETED d ON fa.worker_id = d.worker_id
    )
    BEGIN
        RAISERROR('Неможливо видалити працівника, який має записи про внесення добрив!', 16, 1);
        RETURN;
    END

    -- Якщо записів немає — видаляємо
    DELETE FROM WORKER
    WHERE worker_id IN (SELECT worker_id FROM DELETED);

    PRINT 'Працівника успішно видалено.';
END;
GO

-- Тест 1: спроба видалення працівника з записами (має видати помилку)
DELETE FROM WORKER WHERE worker_id = 1;
GO

-- Тест 2: видалення нового працівника без записів (має успішно виконатись)
INSERT INTO WORKER (worker_id, first_name, last_name, patronymic, hire_date, brigade_id)
VALUES (202, 'Тест', 'Тестовий', 'Тестович', '2024-01-01', 1);
GO
DELETE FROM WORKER WHERE worker_id = 202;
GO


-- ============================================================
-- ЗАВДАННЯ 4: DDL ТРИГЕРИ (CREATE, DROP, ALTER)
-- ============================================================

-- -------------------------------------------------------
-- DDL Тригер 1: Заборона DROP TABLE на рівні БД
-- -------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_DDL_PreventDrop' AND parent_class = 0)
    DROP TRIGGER trg_DDL_PreventDrop ON DATABASE;
GO

CREATE TRIGGER trg_DDL_PreventDrop
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    RAISERROR('Видалення таблиць у цій базі даних заборонено! Зверніться до адміністратора.', 16, 1);
    ROLLBACK;
END;
GO

-- Тест (закоментовано, щоб не зламати БД): розкоментуйте для перевірки
--DROP TABLE BRIGADE;
--GO


-- -------------------------------------------------------
-- DDL Тригер 2: Логування CREATE TABLE у таблицю аудиту
-- -------------------------------------------------------
IF OBJECT_ID('DDL_AUDIT_LOG', 'U') IS NULL
BEGIN
    CREATE TABLE DDL_AUDIT_LOG (
        log_id      INT IDENTITY(1,1) PRIMARY KEY,
        event_type  NVARCHAR(50)  NOT NULL,
        object_name NVARCHAR(200) NOT NULL,
        login_name  NVARCHAR(100) NOT NULL,
        event_date  DATETIME      NOT NULL DEFAULT GETDATE()
    );
END
GO

IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_DDL_LogCreate' AND parent_class = 0)
    DROP TRIGGER trg_DDL_LogCreate ON DATABASE;
GO

CREATE TRIGGER trg_DDL_LogCreate
ON DATABASE
FOR CREATE_TABLE
AS
BEGIN
    DECLARE @EventData XML = EVENTDATA();
    INSERT INTO DDL_AUDIT_LOG (event_type, object_name, login_name)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(50)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(200)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(100)')
    );
END;
GO

-- Тест: створення тестової таблиці — запис потрапить до DDL_AUDIT_LOG
CREATE TABLE TEST_DDL_TABLE (id INT PRIMARY KEY, name VARCHAR(50));
GO

SELECT * FROM DDL_AUDIT_LOG;
GO


-- -------------------------------------------------------
-- DDL Тригер 3: Заборона ALTER TABLE для критичних таблиць
-- -------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_DDL_PreventAlter' AND parent_class = 0)
    DROP TRIGGER trg_DDL_PreventAlter ON DATABASE;
GO

CREATE TRIGGER trg_DDL_PreventAlter
ON DATABASE
FOR ALTER_TABLE
AS
BEGIN
    DECLARE @EventData  XML          = EVENTDATA();
    DECLARE @TableName  NVARCHAR(200);
    SET @TableName = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(200)');

    IF @TableName IN ('BRIGADE','WORKER','EQUIPMENT','LAND_PLOT','FERTILIZER_APPLICATION','FERTILIZER','CROP')
    BEGIN
        RAISERROR('Зміна структури критичних таблиць заборонена!', 16, 1);
        ROLLBACK;
    END
END;
GO

-- Тест для некритичної таблиці (має виконатись):
ALTER TABLE TEST_DDL_TABLE ADD description VARCHAR(200);
GO

-- Тест для критичної таблиці (закоментовано, має видати помилку):
-- ALTER TABLE BRIGADE ADD test_col INT;
-- GO

-- Тимчасово відключаємо тригер заборони DROP, щоб прибрати тестову таблицю
DISABLE TRIGGER trg_DDL_PreventDrop ON DATABASE;
GO
DROP TABLE TEST_DDL_TABLE;
GO
ENABLE TRIGGER trg_DDL_PreventDrop ON DATABASE;
GO


-- ============================================================
-- ЗАВДАННЯ 5: LOGON ТРИГЕР
-- ============================================================

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_triggers WHERE name = 'trg_Logon_Restrict')
    DROP TRIGGER trg_Logon_Restrict ON ALL SERVER;
GO

CREATE TRIGGER trg_Logon_Restrict
ON ALL SERVER
FOR LOGON
AS
BEGIN
    DECLARE @LoginName   NVARCHAR(100) = ORIGINAL_LOGIN();
    DECLARE @CurrentHour INT           = DATEPART(HOUR, GETDATE());

    -- Дозволяємо вхід тільки з 8:00 до 20:00 (не для sa / sysadmin)
    IF IS_SRVROLEMEMBER('sysadmin', @LoginName) = 0
       AND (@CurrentHour < 8 OR @CurrentHour >= 20)
    BEGIN
        RAISERROR('Вхід до бази Farm_Management_Shevchenko дозволено лише у робочі години (08:00-20:00).', 16, 1);
        ROLLBACK;
    END
END;
GO

-- Перевірка: подивитися поточні server-level тригери
SELECT name, type_desc, is_disabled
FROM sys.server_triggers
WHERE name = 'trg_Logon_Restrict';
GO

-- Переходимо назад до нашої бази
USE Farm_Management_Shevchenko;
GO


-- ============================================================
-- ЗАВДАННЯ 6: ТРИГЕРИ ЗА БІЗНЕС-ПРАВИЛАМИ ПРЕДМЕТНОЇ ОБЛАСТІ
-- ============================================================

-- -------------------------------------------------------
-- Бізнес-тригер 1: Перевірка норми внесення добрива
-- Правило: Кількість добрива (amount_kg) не може перевищувати
--          подвійну рекомендовану норму (application_rate)
-- -------------------------------------------------------
IF OBJECT_ID('trg_CheckFertilizerRate', 'TR') IS NOT NULL
    DROP TRIGGER trg_CheckFertilizerRate;
GO

CREATE TRIGGER trg_CheckFertilizerRate
ON FERTILIZER_APPLICATION
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM   INSERTED i
        JOIN   FERTILIZER f ON i.fertilizer_id = f.fertilizer_id
        WHERE  i.amount_kg > f.application_rate * 2
    )
    BEGIN
        RAISERROR('Перевищено допустиму норму внесення добрива (більш ніж вдвічі від рекомендованої)!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Тест 1: перевищення норми — fertilizer_id=1, rate=150, max=300; вносимо 400 (має видати помилку)
-- INSERT INTO FERTILIZER_APPLICATION VALUES (203, 1, 1, 1, 1, '2024-06-02', 400.00, 'Розсів', NULL);
-- GO

-- Тест 2: допустимий обсяг (має виконатись)
INSERT INTO FERTILIZER_APPLICATION
    (application_id, plot_id, fertilizer_id, worker_id, brigade_id, application_date, amount_kg, application_method)
VALUES (203, 1, 1, 1, 1, '2024-06-02', 250.00, 'Розсів');
GO


-- -------------------------------------------------------
-- Бізнес-тригер 2: Відповідність бригади ділянки та запису
-- Правило: Бригада у FERTILIZER_APPLICATION повинна збігатись
--          із бригадою, що обслуговує цю ділянку (LAND_PLOT.brigade_id)
-- -------------------------------------------------------
IF OBJECT_ID('trg_CheckBrigadeConsistency', 'TR') IS NOT NULL
    DROP TRIGGER trg_CheckBrigadeConsistency;
GO

CREATE TRIGGER trg_CheckBrigadeConsistency
ON FERTILIZER_APPLICATION
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM   INSERTED  i
        JOIN   LAND_PLOT lp ON i.plot_id = lp.plot_id
        WHERE  i.brigade_id <> lp.brigade_id
    )
    BEGIN
        RAISERROR('Бригада у записі внесення добрив не відповідає бригаді, що обслуговує цю ділянку!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Тест: ділянка plot_id=1 належить brigade_id=1; вносимо з brigade_id=2 (має видати помилку)
--INSERT INTO FERTILIZER_APPLICATION VALUES (204, 1, 1, 6, 2, '2024-06-03', 100.00, 'Розсів', NULL);
--GO


-- -------------------------------------------------------
-- Бізнес-тригер 3: Перевірка зрошення при призначенні культури
-- Правило: Якщо культура потребує зрошення (requires_irrigation=1),
--          ділянка повинна мати зрошення (has_irrigation=1)
-- -------------------------------------------------------
IF OBJECT_ID('trg_CheckIrrigationRequirement', 'TR') IS NOT NULL
    DROP TRIGGER trg_CheckIrrigationRequirement;
GO

CREATE TRIGGER trg_CheckIrrigationRequirement
ON LAND_PLOT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM   INSERTED i
        JOIN   CROP     c ON i.crop_id = c.crop_id
        WHERE  c.requires_irrigation = 1
          AND  i.has_irrigation      = 0
    )
    BEGIN
        RAISERROR('Неможливо призначити культуру, що потребує зрошення, на ділянку без системи зрошення!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Тест: Кукурудза (crop_id=2) потребує зрошення; ставимо has_irrigation=0 (має видати помилку)
--UPDATE LAND_PLOT SET crop_id = 2, has_irrigation = 0 WHERE plot_id = 2;
--GO

-- Тест коректний: культура без зрошення на ділянці без зрошення
UPDATE LAND_PLOT SET crop_id = 3 WHERE plot_id = 2;  -- Соняшник не потребує зрошення
GO


-- -------------------------------------------------------
-- Бізнес-тригер 4: Попередження при додаванні навичок для техніки на ремонті
-- Правило: Якщо техніка має статус 'Ремонт', система виводить попередження,
--          але не блокує операцію
-- -------------------------------------------------------
IF OBJECT_ID('trg_WarnEquipmentInRepair', 'TR') IS NOT NULL
    DROP TRIGGER trg_WarnEquipmentInRepair;
GO

CREATE TRIGGER trg_WarnEquipmentInRepair
ON WORKER_EQUIPMENT_SKILL
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM   INSERTED  i
        JOIN   EQUIPMENT e ON i.equipment_id = e.equipment_id
        WHERE  e.status = 'Ремонт'
    )
    BEGIN
        -- severity 10 — інформаційне попередження, не скасовує транзакцію
        RAISERROR('УВАГА: Техніка, навичка роботи з якою реєструється, наразі перебуває на ремонті!', 10, 1);
    END
END;
GO

-- Тест: equipment_id=17 має статус 'Ремонт' (видає попередження, але вставляє)
INSERT INTO WORKER_EQUIPMENT_SKILL
    (skill_id, worker_id, equipment_id, skill_level, certification_date, experience_years)
VALUES (205, 5, 17, 'Базовий', '2024-01-01', 1);
GO

SELECT skill_id, worker_id, equipment_id, skill_level FROM WORKER_EQUIPMENT_SKILL WHERE skill_id = 205;
GO


-- ============================================================
-- Очищення тестових даних
-- ============================================================
DELETE FROM FERTILIZER_APPLICATION WHERE application_id IN (201, 202, 203, 204);
DELETE FROM WORKER_EQUIPMENT_SKILL  WHERE skill_id = 205;
GO

-- Таблицю аудиту залишаємо для демонстрації
SELECT * FROM DDL_AUDIT_LOG;
GO