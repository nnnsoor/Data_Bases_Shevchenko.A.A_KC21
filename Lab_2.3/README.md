# Farm Management Database — Шевченко А.А. КС-21

## Опис
База даних управління фермерським господарством (Farm_Management_Shevchenko).
Реалізована на MS SQL Server 2022 у Docker-контейнері.

## Вимоги
- Docker Desktop
- MS SQL Server Management Studio (SSMS)

## Розгортання

### 1. Створити том для збереження даних
docker volume create mssql_farm_data

### 2. Запустити контейнер
docker run -d --name mssql_farm \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=MyPassword123!" \
  -p 1433:1433 \
  -v mssql_farm_data:/var/opt/mssql \
  mcr.microsoft.com/mssql/server:2022-latest

### 3. Підключитись через SSMS
- Server: localhost,1433
- Login: SA
- Password: MyPassword123!

### 4. Виконати скрипти у порядку
1. SETUP.SQL  — створення бази даних і таблиць
2. INSERT.SQL — заповнення таблиць даними
3. UPDATE.SQL — оновлення та видалення даних
4. QUERY2.SQL  — аналітичні запити

## Структура файлів
- SETUP.SQL  — створення та зміна структури таблиць
- INSERT.SQL — початкове заповнення даними
- UPDATE.SQL — оновлення, видалення, транзакції
- QUERY2.SQL  — запити завдань 4–10
