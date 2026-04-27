-- ============================================================
--  ПРАКТИЧНА РОБОТА №7 — ТРАНЗАКЦІЇ
--  База даних: Farm_Management_Shevchenko
-- ============================================================

USE Farm_Management_Shevchenko;
GO

-- ============================================================
-- ЗАВДАННЯ 3. Приклад використання транзакції
-- Сценарій: перевести ділянку plot_id=1 з бригади 1 до бригади 2
-- ============================================================

BEGIN TRAN TransferPlot;

UPDATE LAND_PLOT
SET brigade_id = 2
WHERE plot_id = 1 AND brigade_id = 1;

IF @@ROWCOUNT = 0
BEGIN
    ROLLBACK TRAN TransferPlot;
    PRINT 'ROLLBACK: Ділянку не знайдено або вона вже в іншій бригаді.';
END
ELSE
BEGIN
    COMMIT TRAN TransferPlot;
    PRINT 'COMMIT: Ділянку успішно переведено до бригади 2.';
END
GO

-- ============================================================
-- ЗАВДАННЯ 4. Транзакція з двома операціями та умовою ROLLBACK
-- Сценарій: оновити статус техніки бригади 4;
--           якщо після цього у всій БД не залишилось
--           жодної техніки в ремонті — ROLLBACK
-- ============================================================

BEGIN TRAN;

-- Операція 1: перевести техніку бригади 4 зі статусу 'Ремонт' в 'Активний'
UPDATE EQUIPMENT
SET status = 'Активний'
WHERE brigade_id = 4 AND status = 'Ремонт';

-- Операція 2: оновити дату покупки для щойно активованої техніки
UPDATE EQUIPMENT
SET purchase_date = GETDATE()
WHERE brigade_id = 4 AND status = 'Активний';

-- Умова для ROLLBACK
IF (SELECT COUNT(*) FROM EQUIPMENT WHERE status = 'Ремонт') = 0
BEGIN
    ROLLBACK;
    PRINT 'ROLLBACK: У базі не залишилось техніки в ремонті — підозріла ситуація!';
END
ELSE
BEGIN
    COMMIT;
    PRINT 'COMMIT: Техніку бригади 4 переведено в активний стан.';
END
GO

-- ============================================================
-- ЗАВДАННЯ 5. Перевірка @@ERROR для керування транзакцією
-- Сценарій: оновити норму та % азоту для 'Аміачна селітра'
-- ============================================================

DECLARE @err INT;

BEGIN TRAN;

-- Операція 1
UPDATE FERTILIZER
SET application_rate = 160.00
WHERE fertilizer_name = 'Аміачна селітра';

SET @err = @@ERROR;
IF @err <> 0
BEGIN
    ROLLBACK;
    PRINT 'ROLLBACK: Помилка при оновленні норми. Код: ' + CAST(@err AS VARCHAR);
    RETURN;
END

-- Операція 2
UPDATE FERTILIZER
SET nitrogen_percent = 34.50
WHERE fertilizer_name = 'Аміачна селітра';

SET @err = @@ERROR;
IF @err <> 0
BEGIN
    ROLLBACK;
    PRINT 'ROLLBACK: Помилка при оновленні % азоту. Код: ' + CAST(@err AS VARCHAR);
    RETURN;
END

COMMIT;
PRINT 'COMMIT: Дані добрива успішно оновлено.';
GO

-- ============================================================
-- ЗАВДАННЯ 6. SAVEPOINT — точка збереження
-- Сценарій: оновити площу ділянки 10 (збережеться),
--           потім змінити якість ґрунту (скасується через ROLLBACK до точки)
-- ============================================================

BEGIN TRAN;

-- Операція 1 (збережеться)
UPDATE LAND_PLOT
SET area = 30.00
WHERE plot_id = 10;

PRINT 'Площу ділянки 10 змінено на 30.00 га.';

-- Точка збереження
SAVE TRANSACTION SavePoint1;
PRINT 'Точку збереження SavePoint1 встановлено.';

-- Операція 2 (буде скасована)
UPDATE LAND_PLOT
SET soil_quality_index = 5.0
WHERE plot_id = 10;

PRINT 'Індекс якості ґрунту змінено на 5.0 (буде скасовано).';

-- Відкат до точки збереження
ROLLBACK TRANSACTION SavePoint1;
PRINT 'ROLLBACK до SavePoint1: зміна якості ґрунту скасована.';

-- Підтвердження (тільки операція 1 залишається)
COMMIT;
PRINT 'COMMIT: Площа 30.00 га збережена. Якість ґрунту не змінена.';
GO

-- Перевірка результату
SELECT plot_id, area, soil_quality_index
FROM LAND_PLOT
WHERE plot_id = 10;
GO

-- ============================================================
-- ЗАВДАННЯ 7. TRY...CATCH у транзакціях
-- Сценарій: спроба встановити brigade_id = NULL (порушення NOT NULL)
--           провокує помилку → CATCH виконує ROLLBACK
-- ============================================================

BEGIN TRAN;
BEGIN TRY
    -- Операція 1: оновити номер телефону (успішна)
    UPDATE WORKER
    SET phone_number = '+380501111111'
    WHERE worker_id = 1;

    -- Операція 2: навмисна помилка — NULL у NOT NULL колонку
    UPDATE WORKER
    SET brigade_id = NULL
    WHERE worker_id = 1;

    COMMIT TRAN;
    PRINT 'COMMIT: Дані успішно оновлено.';
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT '=== ПОМИЛКА ===';
    PRINT 'Код:          ' + CAST(ERROR_NUMBER()   AS VARCHAR);
    PRINT 'Повідомлення: ' + ERROR_MESSAGE();
    PRINT 'Рівень:       ' + CAST(ERROR_SEVERITY() AS VARCHAR);
    PRINT 'Рядок:        ' + CAST(ERROR_LINE()     AS VARCHAR);
    PRINT '=== Транзакцію скасовано (ROLLBACK) ===';
END CATCH;
GO

-- ============================================================
-- ЗАВДАННЯ 8. BEGIN TRAN...COMMIT з логуванням змін
-- ============================================================

-- Крок 1: Створити таблицю audit_log (якщо не існує)
IF OBJECT_ID('audit_log', 'U') IS NULL
CREATE TABLE audit_log (
    log_id        INT IDENTITY(1,1) PRIMARY KEY,
    action        VARCHAR(200) NOT NULL,
    table_name    VARCHAR(100) NULL,
    record_id     INT          NULL,
    old_value     VARCHAR(500) NULL,
    new_value     VARCHAR(500) NULL,
    performed_by  VARCHAR(100) NULL,
    log_timestamp DATETIME     NOT NULL DEFAULT GETDATE()
);
GO

-- Крок 2: Транзакція з логуванням
BEGIN TRAN;

DECLARE @oldYield DECIMAL(10,2);
DECLARE @newYield DECIMAL(10,2) = 50.00;

SELECT @oldYield = average_yield
FROM CROP WHERE crop_id = 1;

-- Основна операція
UPDATE CROP
SET average_yield = @newYield
WHERE crop_id = 1;

-- Запис у журнал
INSERT INTO audit_log (action, table_name, record_id, old_value, new_value, performed_by)
VALUES (
    'UPDATE average_yield',
    'CROP',
    1,
    CAST(@oldYield AS VARCHAR),
    CAST(@newYield AS VARCHAR),
    SYSTEM_USER
);

COMMIT;
PRINT 'COMMIT: Врожайність оновлено. Запис у журнал додано.';
GO

-- Перевірка журналу
SELECT * FROM audit_log ORDER BY log_timestamp DESC;
GO

-- ============================================================
-- ЗАВДАННЯ 9. Принцип АТОМАРНОСТІ
-- Сценарій: додати нового працівника (101) + запис про внесення добрива
--           Якщо будь-яка операція падає — ROLLBACK обох
-- ============================================================

BEGIN TRAN AtomicDemo;
BEGIN TRY
    -- Операція A: новий працівник
    INSERT INTO WORKER
        (worker_id, first_name, last_name, patronymic,
         hire_date, phone_number, brigade_id)
    VALUES
        (101, 'Тест', 'Атомарний', 'Тестович',
         GETDATE(), '+380501234599', 1);

    PRINT 'Операція A: працівника 101 додано.';

    -- Операція B: пов'язаний запис (внесення добрива)
    INSERT INTO FERTILIZER_APPLICATION
        (application_id, plot_id, fertilizer_id, worker_id,
         brigade_id, application_date, amount_kg, application_method)
    VALUES
        (101, 1, 1, 101, 1, GETDATE(), 150.00, 'Розсів');

    PRINT 'Операція B: запис про внесення добрива 101 додано.';

    COMMIT TRAN AtomicDemo;
    PRINT 'COMMIT: Обидві операції виконані — атомарність збережена.';
END TRY
BEGIN CATCH
    ROLLBACK TRAN AtomicDemo;
    PRINT 'ROLLBACK: Помилка! Жодна зміна не збережена.';
    PRINT 'Деталі: ' + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- ЗАВДАННЯ 10. Принцип УЗГОДЖЕНОСТІ
-- Сценарій: додати нову бригаду (11) і одночасно призначити їй нову ділянку (101)
--           Зовнішній ключ гарантує: ділянка без бригади — неможлива
-- ============================================================

BEGIN TRAN ConsistencyDemo;
BEGIN TRY
    -- Крок 1: нова бригада
    INSERT INTO BRIGADE
        (brigade_id, foreman_first_name, foreman_last_name,
         foreman_patronymic, formation_date)
    VALUES
        (11, 'Іван', 'Новий', 'Бригадирович', GETDATE());

    PRINT 'Бригаду 11 додано.';

    -- Крок 2: нова ділянка для цієї бригади
    INSERT INTO LAND_PLOT
        (plot_id, area, has_irrigation, soil_quality_index, brigade_id, crop_id)
    VALUES
        (101, 50.00, 1, 8.0, 11, 1);

    PRINT 'Ділянку 101 призначено бригаді 11.';

    -- Крок 3: оновити примітку бригади (лічильник ділянок)
    UPDATE BRIGADE
    SET foreman_patronymic = 'Бригадирович (1 ділянка)'
    WHERE brigade_id = 11;

    COMMIT TRAN ConsistencyDemo;
    PRINT 'COMMIT: База даних у узгодженому стані.';
END TRY
BEGIN CATCH
    ROLLBACK TRAN ConsistencyDemo;
    PRINT 'ROLLBACK: Порушення узгодженості! ' + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- ЗАВДАННЯ 11. Три операції в одній явній транзакції
-- INSERT нового добрива + INSERT пов'язаного застосування + UPDATE приміток
-- ============================================================

BEGIN TRAN ThreeOperations;
BEGIN TRY
    -- Операція 1 (INSERT): нове добриво
    INSERT INTO FERTILIZER
        (fertilizer_id, fertilizer_name, fertilizer_type,
         nitrogen_percent, phosphorus_percent, potassium_percent, application_rate)
    VALUES
        (11, 'Біогумус', 'Органічне', 1.50, 0.80, 1.20, 5000.00);

    PRINT 'Операція 1 (INSERT FERTILIZER): Біогумус додано.';

    -- Операція 2 (INSERT пов'язаного запису): застосування цього добрива
    INSERT INTO FERTILIZER_APPLICATION
        (application_id, plot_id, fertilizer_id, worker_id,
         brigade_id, application_date, amount_kg, application_method, notes)
    VALUES
        (102, 5, 11, 21, 5, GETDATE(), 5000.00, 'Внесення в ґрунт',
         'Нове органічне добриво — тестове застосування');

    PRINT 'Операція 2 (INSERT APPLICATION): Запис про застосування додано.';

    -- Операція 3 (UPDATE): оновити примітки
    UPDATE FERTILIZER_APPLICATION
    SET notes = 'Перевірено: норма 5000 кг/га підтверджена агрономом'
    WHERE application_id = 102;

    PRINT 'Операція 3 (UPDATE APPLICATION): Примітки оновлено.';

    COMMIT TRAN ThreeOperations;

    DECLARE @cnt INT;
    SELECT @cnt = COUNT(*) FROM FERTILIZER;
    PRINT 'COMMIT: Всі три операції виконані.';
    PRINT 'Загальна кількість типів добрив: ' + CAST(@cnt AS VARCHAR);
END TRY
BEGIN CATCH
    ROLLBACK TRAN ThreeOperations;
    PRINT 'ROLLBACK: ' + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- ЗАВДАННЯ 12. Демонстрація AUTOCOMMIT vs явна транзакція
-- ============================================================

-- Autocommit (режим за замовчуванням — кожен оператор = окрема транзакція):
UPDATE CROP SET average_yield = 50.00 WHERE crop_id = 1;
-- SQL Server автоматично виконав BEGIN TRAN та COMMIT (або ROLLBACK при помилці)
PRINT 'Autocommit: UPDATE виконано автоматично як окрема транзакція.';
GO

-- Еквівалент у вигляді явної транзакції:
BEGIN TRAN;
UPDATE CROP SET average_yield = 50.00 WHERE crop_id = 1;
COMMIT;
PRINT 'Явна транзакція: той самий результат, але межі задані програмістом.';
GO

-- Різниця: autocommit НЕ дозволяє об'єднати кілька операцій.
-- Якби між двома UPDATE виникла помилка — перший вже підтверджений (небезпечно!):
--
-- UPDATE CROP SET average_yield = 50.00 WHERE crop_id = 1;  -- вже в БД!
-- UPDATE CROP SET average_yield = NULL  WHERE crop_id = 1;  -- помилка — але перший вже збережений
--
-- З явною транзакцією обидва або підтверджуються, або обидва скасовуються.
GO