# Лабораторна робота №7 — Тригери в MSSQL

**Предмет:** Бази даних  
**Виконала:** Шевченко А. А., група КС-21  
**Університет:** ХНУ імені В. Н. Каразіна

---

## Тема

Робота з тригерами в Microsoft SQL Server. Предметна область — система управління фермою (`Farm_Management_Shevchenko`).

---

## Структура бази даних

Основні таблиці: `Brigade`, `Worker`, `Land_Plot`, `Crop`, `Fertilizer`, `Fertilizer_Application`, `Equipment`, `Worker_Equipment_Skill`.

---

## Реалізовані тригери

### DML тригери (Завдання 3)

| Назва | Тип | Таблиця | Призначення |
|---|---|---|---|
| `trg_AfterInsert_FertApp` | AFTER INSERT | `FERTILIZER_APPLICATION` | Логування нових записів внесення добрив |
| `trg_AfterUpdate_LandPlot` | AFTER UPDATE | `LAND_PLOT` | Фіксація зміни культури на ділянці |
| `trg_AfterDelete_FertApp` | AFTER DELETE | `FERTILIZER_APPLICATION` | Логування видалених записів |
| `trg_InsteadOfDelete_Worker` | INSTEAD OF DELETE | `WORKER` | Блокування видалення працівника з пов'язаними записами |

### DDL тригери (Завдання 4)

| Назва | Подія | Призначення |
|---|---|---|
| `trg_DDL_PreventDrop` | FOR DROP_TABLE | Заборона видалення таблиць |
| `trg_DDL_LogCreate` | FOR CREATE_TABLE | Аудит нових таблиць у `DDL_AUDIT_LOG` |
| `trg_DDL_PreventAlter` | FOR ALTER_TABLE | Захист структури критичних таблиць |

### LOGON тригер (Завдання 5)

`trg_Logon_Restrict` — обмежує вхід до сервера поза робочим часом (08:00–20:00) для звичайних користувачів.

### Бізнес-тригери (Завдання 6)

| Назва | Призначення |
|---|---|
| `trg_CheckFertilizerRate` | Перевірка норми добрива: `amount_kg ≤ application_rate * 2` |
| `trg_CheckBrigadeConsistency` | Відповідність бригади у записі бригаді ділянки |
| `trg_CheckIrrigationRequirement` | Заборона культури з зрошенням на ділянці без зрошення |
| `trg_WarnEquipmentInRepair` | Попередження при реєстрації навички для техніки на ремонті |

---

## Технології

- Microsoft SQL Server (T-SQL)
- Псевдотаблиці `INSERTED` / `DELETED`
- Функції `EVENTDATA()`, `RAISERROR`, `ORIGINAL_LOGIN()`, `IS_SRVROLEMEMBER()`
