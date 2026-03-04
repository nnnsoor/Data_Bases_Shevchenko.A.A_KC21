# Farm Management — Docker MS SQL Server

База даних управління фермерським господарством,
розгорнута в Docker-контейнері.

## Вимоги
- Docker Desktop встановлений і запущений

## Швидкий старт

### 1. Створити том
docker volume create mssql_farm_data

### 2. Запустити контейнер
docker run -d \
  --name mssql_farm \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=MyPassword123!" \
  -p 1433:1433 \
  -v mssql_farm_data:/var/opt/mssql \
  mcr.microsoft.com/mssql/server:2022-latest

### 3. Перевірити що контейнер запущений
docker ps

### 4. Підключитись через SSMS
Server:   localhost,1433
Login:    SA
Password: MyPassword123!
Увімкнути: Trust server certificate

### 5. Виконати скрипти в SSMS (по порядку)
1. SETUP.sql   — створення таблиць
2. INSERT.sql  — заповнення даними
3. UPDATE.sql  — оновлення даних
4. QUERY.sql   — аналітичні запити

## Зупинка та видалення контейнера
docker stop mssql_farm
docker rm mssql_farm

## Дані зберігаються у томі
docker volume inspect mssql_farm_data

## Структура БД
- BRIGADE — бригади
- CROP — культури
- FERTILIZER — добрива
- LAND_PLOT — земельні ділянки
- WORKER — працівники
- EQUIPMENT — техніка
- WORKER_EQUIPMENT_SKILL — навички
- FERTILIZER_APPLICATION — внесення добрив
