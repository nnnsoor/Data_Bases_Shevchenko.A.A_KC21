# Farm Management Database — Практична робота №7

**База даних:** `Farm_Management_Shevchenko`  
**Предметна область:** Управління сільськогосподарською фермою  

---

## Опис предметної області

Система управління фермою: земельні ділянки, бригади, культури, добрива, техніка та працівники. Кожну ділянку обслуговує одна бригада; бригада може мати кілька ділянок. Фіксуються записи внесення добрив із зазначенням дати, кількості та методу.

---

## Структура репозиторію

| Файл | Призначення |
|------|-------------|
| `SETUP.SQL` | Створення таблиць (`DROP + CREATE`) |
| `INSERT.SQL` | Базові дані (100 рядків у кожній таблиці) |
| `UPDATE.SQL` | Оновлення та видалення записів |
| `QUERY.SQL` | Запити варіанта, індекси, аудит індексів |
| `PROCEDURES.SQL` | Системні, тимчасові та користувацькі процедури |
| `FUNCTIONS.SQL` | SEQUENCE + процедура вставки з генерацією PK |

---

## Індекси (QUERY.SQL)

| Індекс | Тип | Таблиця | Призначення |
|--------|-----|---------|-------------|
| `IX_FA_ApplicationDate` | Некластеризований | `FERTILIZER_APPLICATION` | Пошук за датою внесення |
| `IX_LPDEMO_Clustered` | Кластеризований | `LAND_PLOT_DEMO` (тест) | Фізичний порядок за brigade_id |
| `UX_Worker_Phone` | Унікальний | `WORKER` | Унікальність телефону |
| `IX_FA_PlotDate_Include` | З включеними стовпцями | `FERTILIZER_APPLICATION` | Covering index (plot_id + дата) |
| `IX_Equipment_Active` | Фільтрований | `EQUIPMENT` | Тільки активна техніка |

---

## Процедури (PROCEDURES.SQL)

### Системні (`sp_`)
```sql
EXEC sp_helpindex 'FERTILIZER_APPLICATION'; -- перегляд індексів таблиці
EXEC sp_spaceused 'WORKER';                 -- розмір таблиці (рядки, KB)
EXEC sp_rename N'таблиця.старий', N'новий', N'INDEX'; -- перейменування
```

### Глобальні тимчасові (`##`)
```sql
EXEC ##GetBrigadeFertilizerStats;   -- статистика внесень по бригадах
EXEC ##TopFertilizers;              -- топ-5 добрив за кількістю
EXEC ##PlotsWithoutFertilizer;      -- ділянки без добрив у поточному році
```
> Доступні всім сесіям. Зберігаються в `tempdb`. Видаляються при перезапуску сервера.

### Локальні тимчасові (`#`)
```sql
EXEC #GetActiveBrigadeEquipment @BrigadeID = 1;             -- активна техніка бригади
EXEC #CountFertilizerByType @FertType = N'Азотне', @Year = 2024; -- добрива за типом і роком
EXEC #AvgPlotAreaByBrigade @BrigadeID = 3;                  -- площа ділянок бригади
```
> Доступні лише поточній сесії. Видаляються при закритті вкладки.

### Процедури користувача (транзакції)
```sql
EXEC usp_UpdateForeman @BrigadeID=1, @NewFirstName=N'Іван', @NewLastName=N'Коваленко';
EXEC usp_TransferPlot @PlotID=5, @NewBrigadeID=2;
EXEC usp_DeleteApplicationsByYear @Year=2023; -- обережно!
```
> Всі три використовують `BEGIN TRANSACTION / COMMIT / ROLLBACK` + `TRY/CATCH`.

### Вставка N рядків (Завдання 10)
```sql
EXEC usp_GenerateApplicationRows @RowCount = 400;  -- додає 400 рядків
```

---

## Функція з послідовністю (FUNCTIONS.SQL)

```sql
-- Перевірити існування запису:
SELECT dbo.fn_ApplicationExists(1); -- повертає 1 або 0

-- Вставити новий запис через SEQUENCE:
DECLARE @pk INT;
EXEC dbo.usp_InsertApplicationWithSequence
    @plot_id=1, @fertilizer_id=1, @worker_id=1, @brigade_id=1,
    @application_date='2024-06-01', @amount_kg=200.00,
    @application_method=N'Розсів', @notes=NULL,
    @inserted_id=@pk OUTPUT;
SELECT @pk; -- повертає новий PK або NULL при помилці FK
```

> `NEXT VALUE FOR` заборонено в скалярних UDF — реалізовано через процедуру з `OUTPUT`-параметром.

---

## Відмінності функцій від процедур

| | Функція (UDF) | Процедура (SP) |
|-|--------------|----------------|
| Повертає | Обов'язково значення (`RETURNS`) | Через `OUTPUT` або `SELECT` |
| У `SELECT` | Так: `SELECT dbo.fn_Name()` | Ні |
| Транзакції | Не можна | `BEGIN TRAN / COMMIT / ROLLBACK` |
| `INSERT/UPDATE` | Заборонено у скалярних | Повністю |
| `TRY/CATCH` | Не підтримується | Повністю |
