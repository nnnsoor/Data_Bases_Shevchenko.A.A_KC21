# Система управління фермерським господарством

> **Лабораторна робота №7**: Реалізація фізичної моделі бази даних  
> **Курс**: Бази даних  
> **Автор**: [Ваше ПІБ]  
> **Група**: [Ваша група]  
> **Дата**: Листопад 2024

---

## Опис предметної області

### Загальна інформація

Система призначена для автоматизації обліку та управління діяльністю фермерського господарства. Вона охоплює всі основні аспекти роботи ферми: від управління земельними ресурсами до координації роботи бригад та обліку використання добрив.

### Основні функції системи:

- **Облік земельних ділянок** - реєстрація та характеристика кожної ділянки (площа, якість ґрунту, наявність зрошення)
- **Управління посівами** - інформація про культури, врожайність, вимоги до вирощування
- **Управління персоналом** - облік бригад, працівників та їхніх навичок
- **Облік техніки** - реєстрація обладнання, відстеження стану та закріплення за працівниками
- **Облік добрив** - типи добрив, норми внесення, журнал застосування
- **Аналітика** - звіти про використання ресурсів, продуктивність, планування

### Детальний опис

**Земельні ділянки:**
На фермі є кілька ділянок землі, яким присвоєні унікальні номери. Кожна ділянка характеризується площею (в гектарах), наявністю або відсутністю зрошення, індексом якості ґрунту (1-10), посіяною в поточному сезоні культурою. Відома середня врожайність кожної з оброблюваних культур, а також перелік внесених на кожну ділянку в цьому сезоні добрив.

**Культури:**
Для кожної культури відомо: назва, очікувана врожайність (т/га), чи потрібне для неї зрошення, тривалість вегетаційного періоду (днів), необхідні добрива. Система підтримує як зернові (пшениця, ячмінь, кукурудза), так і технічні (соняшник, ріпак), овочеві та кормові культури.

**Бригади та працівники:**
Кожну ділянку обслуговує одна бригада, але будь-яка бригада може обслуговувати більше однієї ділянки. Бригада має унікальний номер і характеризується: П.І.Б. бригадира, датою формування, статусом (активна/тимчасова/розформована), контактною інформацією.

Про кожного працівника відомо: П.І.Б., дата народження, дата прийому на роботу, бригада, контактна інформація, адреса. Для кожного працівника зберігається інформація про те, якими видами сільгоспмашин (одним, кількома, жодним) він може керувати, рівень його майстерності (1-5), дату сертифікації та роки досвіду.

**Техніка та обладнання:**
Система обліковує всю сільськогосподарську техніку: трактори, комбайни, сівалки, обприскувачі, культиватори тощо. Для кожної одиниці зберігається: тип, модель, виробник, дата придбання, серійний номер, вартість, поточний стан (активна/на обслуговуванні/зламана/списана).

**Добрива:**
В системі обліковуються всі типи добрив: мінеральні (азотні, фосфорні, калійні), органічні (гній, компост), комплексні (NPK) та мікродобрива. Для кожного типу зберігається склад (відсоток поживних речовин), рекомендована норма внесення (кг/га), тип добрива.

Журнал внесення добрив фіксує: на яку ділянку, яке добриво, коли, в якій кількості, яким методом (ручний/механізований/зрошення/авіаційний) та ким було внесено.

---

## ER-модель

### Концептуальна модель

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Brigade   │────1:N──│  Land_Plot   │────N:1──│    Crop     │
└─────────────┘         └──────────────┘         └─────────────┘
      │                        │                         
      │                        │                         
     1:N                      1:N                       
      │                        │                         
      │                        │                         
┌─────────────┐         ┌──────────────────┐            
│   Worker    │         │ Fertilizer_Appl. │            
└─────────────┘         └──────────────────┘            
      │                        │                         
     N:M                       │                         
      │                       N:1                        
┌─────────────┐                │                         
│  Equipment  │         ┌─────────────┐                 
└─────────────┘         │ Fertilizer  │                 
                        └─────────────┘                 
```

### Логічна модель (8 таблиць)

1. **Brigade** (Бригади) - інформація про робочі бригади
2. **Worker** (Працівники) - персонал господарства
3. **Equipment** (Обладнання) - сільськогосподарська техніка
4. **Worker_Equipment_Skill** (Навички) - зв'язок працівників з технікою
5. **Crop** (Культури) - види культур що вирощуються
6. **Land_Plot** (Ділянки) - земельні ділянки
7. **Fertilizer** (Добрива) - типи добрив
8. **Fertilizer_Application** (Внесення добрив) - журнал застосування

---

## Структура бази даних

### Основні таблиці

#### 1️. Brigade (Бригади)
```sql
brigade_id          INT PRIMARY KEY IDENTITY
foreman_first_name  NVARCHAR(100) NOT NULL
foreman_last_name   NVARCHAR(100) NOT NULL
foreman_patronymic  NVARCHAR(100)
formation_date      DATE NOT NULL
status              VARCHAR(20) DEFAULT 'active'
contact_phone       VARCHAR(20)
```

#### 2️. Crop (Культури)
```sql
crop_id             INT PRIMARY KEY IDENTITY
crop_name           NVARCHAR(100) NOT NULL UNIQUE
expected_yield      DECIMAL(10,2) NOT NULL
requires_irrigation BIT DEFAULT 0
growing_season_days INT NOT NULL
description         NVARCHAR(500)
```

#### 3️. Land_Plot (Земельні ділянки)
```sql
plot_id             INT PRIMARY KEY IDENTITY
area                DECIMAL(10,2) NOT NULL
has_irrigation      BIT DEFAULT 0
soil_quality_index  TINYINT NOT NULL (1-10)
brigade_id          INT NOT NULL FK → Brigade
crop_id             INT NULL FK → Crop
cadastral_number    VARCHAR(50) UNIQUE
```

#### 4️. Equipment (Обладнання)
```sql
equipment_id        INT PRIMARY KEY IDENTITY
equipment_type      NVARCHAR(100) NOT NULL
model               NVARCHAR(100)
manufacturer        VARCHAR(100)
purchase_date       DATE NOT NULL
status              VARCHAR(20) DEFAULT 'active'
serial_number       VARCHAR(50)
purchase_price      DECIMAL(12,2)
```

#### 5️. Worker (Працівники)
```sql
worker_id           INT PRIMARY KEY IDENTITY
brigade_id          INT NOT NULL FK → Brigade
first_name          NVARCHAR(100) NOT NULL
last_name           NVARCHAR(100) NOT NULL
patronymic          NVARCHAR(100)
hire_date           DATE NOT NULL
birth_date          DATE
phone_number        VARCHAR(20) UNIQUE
address             NVARCHAR(300)
```

#### 6️. Worker_Equipment_Skill (Навички)
```sql
worker_id           INT FK → Worker
equipment_id        INT FK → Equipment
skill_level         TINYINT (1-5)
certification_date  DATE
experience_years    DECIMAL(4,1)
PRIMARY KEY (worker_id, equipment_id)
```

#### 7️. Fertilizer (Добрива)
```sql
fertilizer_id       INT PRIMARY KEY IDENTITY
fertilizer_name     NVARCHAR(100) NOT NULL
fertilizer_type     VARCHAR(50) NOT NULL
nitrogen_percent    DECIMAL(5,2)
phosphorus_percent  DECIMAL(5,2)
potassium_percent   DECIMAL(5,2)
application_rate    DECIMAL(8,2) NOT NULL
```

#### 8️. Fertilizer_Application (Внесення добрив)
```sql
application_id      INT PRIMARY KEY IDENTITY
plot_id             INT NOT NULL FK → Land_Plot
fertilizer_id       INT NOT NULL FK → Fertilizer
application_date    DATE NOT NULL
amount_kg           DECIMAL(10,2) NOT NULL
application_method  VARCHAR(30)
applied_by_worker_id INT FK → Worker
notes               NVARCHAR(300)
```

### Статистика

- **Таблиць**: 8
- **Атрибутів**: 64
- **Зв'язків**: 7 (FOREIGN KEY)
- **Обмежень цілісності**: 35+
- **Індексів**: 12+

---

## Бізнес-правила

### Обмеження цілісності

#### Сутнісна цілісність (Entity Integrity)
- Кожна бригада має унікальний ідентифікатор
- Кожна ділянка має унікальний номер
- Кожна культура має унікальну назву
- Всі первинні ключі - NOT NULL

#### Доменна цілісність (Domain Integrity)
- Площа ділянки завжди більше 0
- Індекс якості ґрунту: 1-10
- Рівень навички працівника: 1-5
- Відсоток поживних речовин: 0-100
- Дата формування/найму не в майбутньому

#### Посилальна цілісність (Referential Integrity)
- Кожна ділянка закріплена за бригадою
- Кожен працівник належить до бригади
- Внесення добрив прив'язане до ділянки та типу добрива
- Каскадне видалення: Brigade → Worker → Skills
- SET NULL: Crop → Land_Plot (ділянка може бути незасіяною)

#### Користувацька цілісність (User-Defined)
- Статус бригади: active | disbanded | temporary
- Статус обладнання: active | maintenance | broken | retired
- Тип добрива: organic | mineral | complex | micronutrient
- Метод внесення: manual | mechanical | irrigation | aerial
- Email та телефон унікальні (якщо вказані)
- Кадастровий номер унікальний (якщо вказаний)

---

## Встановлення та запуск

### Крок 1: Встановлення SQL Server

```bash
# Завантажити SQL Server Express
https://www.microsoft.com/en-us/sql-server/sql-server-downloads

# Встановити SSMS
https://aka.ms/ssmsfullsetup
```

### Крок 2: Створення бази даних

```sql
-- 1. Відкрийте SSMS
-- 2. Підключіться до localhost\SQLEXPRESS
-- 3. Відкрийте файл SETUP.SQL
-- 4. Виконайте скрипт (F5)
```

Або з командного рядка:

```bash
sqlcmd -S localhost\SQLEXPRESS -i SETUP.SQL
```

### Крок 3: Наповнення даними

```sql
-- 1. Відкрийте файл INSERT.SQL
-- 2. Виконайте скрипт (F5)
-- Очікуваний час: 2-5 хвилин
```

### Крок 4: Перевірка

```sql
USE FarmManagementDB;
GO

-- Перевірити кількість записів
SELECT 
    'Brigade' AS TableName, COUNT(*) AS Records FROM Brigade
UNION ALL
SELECT 'Crop', COUNT(*) FROM Crop
UNION ALL
SELECT 'Land_Plot', COUNT(*) FROM Land_Plot
UNION ALL
SELECT 'Worker', COUNT(*) FROM Worker;
```

Очікуваний результат:
- Brigade: 50 записів
- Crop: 25 записів
- Land_Plot: 1000 записів
- Worker: 500 записів
- Equipment: 100 записів
- **Загалом: 5700+ записів**

---

## Приклади запитів

### 1. Інформація про всі ділянки з бригадами

```sql
SELECT 
    lp.plot_id AS [Номер ділянки],
    lp.area AS [Площа (га)],
    CASE WHEN lp.has_irrigation = 1 THEN 'Так' ELSE 'Ні' END AS [Зрошення],
    lp.soil_quality_index AS [Якість ґрунту],
    b.foreman_last_name + ' ' + b.foreman_first_name AS [Бригадир],
    c.crop_name AS [Культура]
FROM Land_Plot lp
INNER JOIN Brigade b ON lp.brigade_id = b.brigade_id
LEFT JOIN Crop c ON lp.crop_id = c.crop_id
ORDER BY lp.plot_id;
```

### 2. Працівники з їх навичками керування технікою

```sql
SELECT 
    w.last_name + ' ' + w.first_name AS [Працівник],
    b.foreman_last_name AS [Бригадир],
    e.equipment_type AS [Тип техніки],
    wes.skill_level AS [Рівень (1-5)],
    wes.experience_years AS [Роки досвіду]
FROM Worker w
INNER JOIN Brigade b ON w.brigade_id = b.brigade_id
INNER JOIN Worker_Equipment_Skill wes ON w.worker_id = wes.worker_id
INNER JOIN Equipment e ON wes.equipment_id = e.equipment_id
WHERE wes.skill_level >= 4
ORDER BY w.last_name;
```

### 3. Культури з максимальною врожайністю

```sql
SELECT TOP 5
    crop_name AS [Культура],
    expected_yield AS [Врожайність (т/га)],
    growing_season_days AS [Вегетація (днів)],
    CASE WHEN requires_irrigation = 1 THEN 'Потрібне' ELSE 'Не потрібне' END AS [Зрошення]
FROM Crop
ORDER BY expected_yield DESC;
```

### 4. Внесення добрив за останній місяць

```sql
SELECT 
    lp.plot_id AS [Ділянка],
    f.fertilizer_name AS [Добриво],
    fa.amount_kg AS [Кількість (кг)],
    fa.application_date AS [Дата],
    fa.application_method AS [Метод],
    w.last_name AS [Працівник]
FROM Fertilizer_Application fa
INNER JOIN Land_Plot lp ON fa.plot_id = lp.plot_id
INNER JOIN Fertilizer f ON fa.fertilizer_id = f.fertilizer_id
LEFT JOIN Worker w ON fa.applied_by_worker_id = w.worker_id
WHERE fa.application_date >= DATEADD(MONTH, -1, GETDATE())
ORDER BY fa.application_date DESC;
```

### 5. Статистика по бригадах

```sql
SELECT 
    b.foreman_last_name AS [Бригадир],
    COUNT(DISTINCT lp.plot_id) AS [Кількість ділянок],
    SUM(lp.area) AS [Загальна площа (га)],
    COUNT(DISTINCT w.worker_id) AS [Кількість працівників],
    AVG(lp.soil_quality_index) AS [Середня якість ґрунту]
FROM Brigade b
LEFT JOIN Land_Plot lp ON b.brigade_id = lp.brigade_id
LEFT JOIN Worker w ON b.brigade_id = w.brigade_id
GROUP BY b.brigade_id, b.foreman_last_name
ORDER BY SUM(lp.area) DESC;
```

---

## Технології

- **СУБД**: Microsoft SQL Server 2022 Express
- **IDE**: SQL Server Management Studio (SSMS) 19
- **Мова**: T-SQL (Transact-SQL)
- **Версія SQL**: SQL Server 2019+
- **Кодування**: UTF-8 (підтримка кирилиці)

### Використані можливості T-SQL:

- IDENTITY для автоінкременту
- FOREIGN KEY з CASCADE/SET NULL
- CHECK constraints для валідації
- DEFAULT значення
- UNIQUE обмеження
- Індекси для оптимізації
- Табличні змінні
- Цикли WHILE
- Умовні вирази CASE
- Функції дати (GETDATE, DATEADD)
- Агрегатні функції (COUNT, SUM, AVG)
- JOIN операції

---

## Результати

### Створені об'єкти:

- 1 база даних
- 8 таблиць
- 8 первинних ключів
- 7 зовнішніх ключів
- 35+ обмежень цілісності
- 12+ індексів
- 5700+ записів

### Покриття функціоналу:

- Облік земельних ресурсів (1000 ділянок)
- Управління персоналом (50 бригад, 500 працівників)
- Облік техніки (100 одиниць обладнання)
- Облік добрив (30 типів, 2500 застосувань)
- Управління культурами (25 видів)
- Реєстрація навичок (1500 сертифікацій)

---
