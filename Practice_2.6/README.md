# Практична робота №2.6— Транзакції у MS SQL Server

**База даних:** `Farm_Management_Shevchenko`  
**Тема:** Транзакції, властивості ACID, ROLLBACK, SAVEPOINT, TRY...CATCH

---

## Файли

| Файл | Призначення |
|------|-------------|
| `SETUP.SQL` | Створення таблиць БД |
| `INSERT.SQL` | Наповнення тестовими даними |
| `TRANSACTIONS.SQL` | Скрипти транзакцій (завдання 3–12) |

---

## Запуск через Docker

### 1. Створити том і запустити контейнер

```bash
docker volume create mssql_data

docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourPassword123!" \
  -p 1433:1433 \
  -v mssql_data:/var/opt/mssql \
  --name mssql_farm \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

### 2. Переконатись що контейнер працює

```bash
docker ps
```

### 3. Виконати скрипти

```bash
docker exec -i mssql_farm /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword123!" < SETUP.SQL

docker exec -i mssql_farm /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword123!" < INSERT.SQL

docker exec -i mssql_farm /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword123!" < TRANSACTIONS.SQL
```

> Або підключись через **SSMS** → `localhost,1433` / логін `sa` і виконуй скрипти вручну.

### 4. Зупинити / видалити контейнер

```bash
docker stop mssql_farm
docker rm mssql_farm
```

---

## Що реалізовано

- `BEGIN TRAN / COMMIT / ROLLBACK` — базова транзакція
- Умовний `ROLLBACK` за результатом перевірки
- Контроль помилок через `@@ERROR`
- Точка збереження `SAVE TRANSACTION`
- Обробка помилок `TRY...CATCH`
- Логування змін у таблицю `audit_log`
- Принцип **Атомарності** — все або нічого
- Принцип **Узгодженості** — зовнішні ключі + транзакція
- Три операції (INSERT + INSERT + UPDATE) в одній транзакції
- Порівняння **autocommit** vs явна транзакція
