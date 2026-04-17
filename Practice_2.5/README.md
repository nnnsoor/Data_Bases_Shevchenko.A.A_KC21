# Практична робота №5 — Індекси в SQL Server

**Предметна область:** Управління фермерським господарством  
**База даних:** `Farm_Management_Shevchenko`

---

## Запуск через Docker

### 1. Створити том для збереження даних

```bash
docker volume create farm_db_data
```

### 2. Запустити контейнер MS SQL Server 2022

```bash
docker run -d \
  --name farm_mssql \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" \
  -p 1433:1433 \
  -v farm_db_data:/var/opt/mssql \
  mcr.microsoft.com/mssql/server:2022-latest
```

### 3. Перевірити, що контейнер запущено

```bash
docker ps -a | grep farm_mssql
```

Статус має бути `Up`.

### 4. Створити базу даних

```bash
docker exec -it farm_mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "YourStrong@Passw0rd" \
  -No -Q "CREATE DATABASE Farm_Management_Shevchenko"
```

### 5. Скопіювати SQL-файли в контейнер

```bash
docker cp SETUP.SQL  farm_mssql:/tmp/SETUP.SQL
docker cp INSERT.SQL farm_mssql:/tmp/INSERT.SQL
docker cp QUERY.SQL  farm_mssql:/tmp/QUERY.SQL
```

### 6. Виконати скрипти по черзі

```bash
docker exec -it farm_mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "YourStrong@Passw0rd" \
  -No -d Farm_Management_Shevchenko -i /tmp/SETUP.SQL

docker exec -it farm_mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "YourStrong@Passw0rd" \
  -No -d Farm_Management_Shevchenko -i /tmp/INSERT.SQL

docker exec -it farm_mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "YourStrong@Passw0rd" \
  -No -d Farm_Management_Shevchenko -i /tmp/QUERY.SQL
```

### 7. Підключитись через SSMS

## Зупинка та видалення контейнера

```bash
# Зупинити контейнер
docker stop farm_mssql

# Запустити знову (дані збережено у томі)
docker start farm_mssql

# Видалити контейнер повністю
docker rm -f farm_mssql

# Видалити том з даними
docker volume rm farm_db_data
```

---

## Таблиці бази даних

| Таблиця | Опис | Записів |
|---|---|---|
| `BRIGADE` | Бригади та бригадири | 10 |
| `CROP` | Сільськогосподарські культури | 10 |
| `FERTILIZER` | Добрива та їх склад | 10 |
| `LAND_PLOT` | Земельні ділянки | 100 |
| `WORKER` | Працівники | 100 |
| `EQUIPMENT` | Сільгосптехніка | 100 |
| `WORKER_EQUIPMENT_SKILL` | Навички роботи з технікою | 100 |
| `FERTILIZER_APPLICATION` | Внесення добрив | 100 |

---

## Індекси, створені в лабораторній роботі

| Назва індексу | Таблиця | Тип | Завдання |
|---|---|---|---|
| `IX_LandPlot_Brigade_Clustered` | `LAND_PLOT` | CLUSTERED | 5 |
| `IX_FertApp_Date` | `FERTILIZER_APPLICATION` | NONCLUSTERED | 6 |
| `IX_Worker_BrigadeId` | `WORKER` | NONCLUSTERED | 6 |
| `IX_LandPlot_Crop_SoilQuality` | `LAND_PLOT` | NONCLUSTERED | 6 |
| `IX_Worker_PhoneNumber_Unique` | `WORKER` | UNIQUE | 7 |
| `IX_FertApp_PlotId_Include` | `FERTILIZER_APPLICATION` | NONCLUSTERED + INCLUDE | 8 |
| `IX_Equipment_Status_Repair` | `EQUIPMENT` | FILTERED | 9 |
| `IX_LandPlot_Irrigated` | `LAND_PLOT` | FILTERED | 9 |
