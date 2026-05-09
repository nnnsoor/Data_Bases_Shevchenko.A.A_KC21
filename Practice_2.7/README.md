# Farm Management — Shevchenko

База даних системи управління фермерським господарством.  
СУБД: **MS SQL Server 2022** у Docker-контейнері.

---

## Структура репозиторію

```
├── SETUP.SQL                   — створення таблиць
├── INSERT.SQL                  — тестові дані
├── INTEGRITY_CONSTRAINTS.SQL   — обмеження цілісності (ЛР7)
├── TRANSACTIONS.SQL            — приклади транзакцій (ЛР7)
└── README.md
```

---

## Запуск через Docker

### 1. Створити том для даних

```bash
docker volume create farm_mssql_data
```

### 2. Запустити контейнер

```bash
docker run -d \
  --name farm_mssql \
  -e ACCEPT_EULA=Y \
  -e SA_PASSWORD=YourStrong@Passw0rd \
  -p 1433:1433 \
  -v farm_mssql_data:/var/opt/mssql \
  mcr.microsoft.com/mssql/server:2022-latest
```

### 3. Перевірити що контейнер працює

```bash
docker ps
```

### 4. Ініціалізувати базу даних

```bash
# Створити БД і таблиці
docker exec -i farm_mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P 'YourStrong@Passw0rd' -No \
  -i SETUP.SQL

# Заповнити тестовими даними
docker exec -i farm_mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P 'YourStrong@Passw0rd' -No \
  -i INSERT.SQL
```

### 5. Підключитися через sqlcmd

```bash
docker exec -it farm_mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P 'YourStrong@Passw0rd' -No
```

---


## Зупинка та видалення контейнера

```bash
docker stop farm_mssql
docker rm farm_mssql

# Видалити том (якщо потрібно)
docker volume rm farm_mssql_data
```
