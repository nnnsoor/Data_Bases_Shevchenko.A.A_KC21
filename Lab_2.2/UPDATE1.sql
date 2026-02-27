USE Farm_Management_Shevchenko;
GO

UPDATE Brigade 
SET foreman_last_name = 'Шевченко-Петренко'
WHERE brigade_id = 1;
PRINT 'Оновлено прізвище бригадира.';
GO

UPDATE Worker 
SET brigade_id = 2
WHERE worker_id = 2;
PRINT 'Працівника переведено.';
GO

UPDATE Equipment 
SET status = 'справний'
WHERE equipment_id = 3;
PRINT 'Статус техніки оновлено.';
GO

UPDATE Worker 
SET email = CASE worker_id
                WHEN 1 THEN 'oleg.shevchenko@example.com'
                WHEN 2 THEN 'petro.bond@example.com'
                WHEN 3 THEN 'n.lysenko@example.com'
                ELSE 'default@farm.ua'
            END
WHERE worker_id IN (1,2,3);
PRINT 'Email-адреси додано.';
GO

UPDATE Worker 
SET passport_number = CASE worker_id
                        WHEN 1 THEN 'МК123456'
                        WHEN 2 THEN 'МК654321'
                        WHEN 3 THEN 'МК789012'
                      END
WHERE worker_id IN (1,2,3);
PRINT 'Паспортні дані додано.';
GO

BEGIN TRANSACTION FireWorker1;
    DECLARE @worker_to_fire INT = 3;

    DELETE FROM Worker_Equipment_Skill WHERE worker_id = @worker_to_fire;
    DELETE FROM Fertilizer_Application WHERE applied_by_worker_id = @worker_to_fire;
    DELETE FROM Worker WHERE worker_id = @worker_to_fire;

    IF @@ERROR = 0
    BEGIN
        COMMIT TRANSACTION FireWorker1;
        PRINT 'Працівника звільнено (видалено разом з навичками та історією внесень).';
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION FireWorker1;
        PRINT 'Помилка при звільненні працівника.';
    END
GO

DELETE FROM Equipment WHERE status = 'списаний';
PRINT 'Списана техніка видалена.';
GO


IF OBJECT_ID('Temp_Log', 'U') IS NULL
BEGIN
    CREATE TABLE Temp_Log (
        log_id INT IDENTITY(1,1),
        log_date DATETIME DEFAULT GETDATE(),
        message NVARCHAR(255)
    );
    PRINT 'Таблицю Temp_Log створено.';
END
GO

INSERT INTO Temp_Log (message) VALUES ('Тестовий запис 1'), ('Тестовий запис 2');
PRINT 'Таблицю Temp_Log заповнено.';
GO

TRUNCATE TABLE Temp_Log;
PRINT 'Таблицю Temp_Log очищено (TRUNCATE).';
GO

DROP TABLE Temp_Log;
PRINT 'Таблицю Temp_Log видалено.';
GO

BEGIN TRANSACTION BuyEquipment;
    INSERT INTO Equipment (equipment_type, model, manufacture_year, purchase_date, status)
    VALUES ('Трактор', 'New Holland T7.270', 2024, '2026-02-10', 'справний');
    
    IF @@ERROR = 0
    BEGIN
        COMMIT TRANSACTION BuyEquipment;
        PRINT 'Нову техніку додано.';
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION BuyEquipment;
        PRINT 'Помилка при додаванні техніки.';
    END
GO

BEGIN TRANSACTION HireWorker;
    INSERT INTO Worker (brigade_id, first_name, last_name, patronymic, hire_date, phone_number, email, passport_number)
    VALUES (1, 'Андрій', 'Мельник', 'Вікторович', '2026-02-12', '099-111-22-33', 'a.melnyk@farm.ua', 'МК555666');
    
    IF @@ERROR = 0
    BEGIN
        COMMIT TRANSACTION HireWorker;
        PRINT 'Нового працівника найнято.';
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION HireWorker;
        PRINT 'Помилка при найманні працівника.';
    END
GO

BEGIN TRANSACTION FireWorker2;
    DECLARE @worker_id_to_fire INT = 1; 
    
    IF EXISTS (SELECT 1 FROM Brigade 
               WHERE brigade_id = (SELECT brigade_id FROM Worker WHERE worker_id = @worker_id_to_fire) 
                 AND foreman_last_name = 'Шевченко-Петренко')
    BEGIN
        PRINT 'Не можна звільнити бригадира!';
        ROLLBACK TRANSACTION FireWorker2;
    END
    ELSE
    BEGIN
        DELETE FROM Worker_Equipment_Skill WHERE worker_id = @worker_id_to_fire;
        DELETE FROM Fertilizer_Application WHERE applied_by_worker_id = @worker_id_to_fire;
        DELETE FROM Worker WHERE worker_id = @worker_id_to_fire;
        
        IF @@ERROR = 0
        BEGIN
            COMMIT TRANSACTION FireWorker2;
            PRINT 'Працівника звільнено.';
        END
        ELSE
        BEGIN
            ROLLBACK TRANSACTION FireWorker2;
            PRINT 'Помилка при звільненні.';
        END
    END
GO

