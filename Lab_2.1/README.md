## ЗВІТ
### до лабораторної роботи №1
### "Створення фізичної моделі бази даних"

**Виконала:** студентка групи КС-21 Шевченко А.А.

---

### 1. Вербальна модель предметної області

На фермі є кілька ділянок землі, яким присвоєні унікальні номери. Кожна ділянка характеризується площею, наявністю або відсутністю зрошення, посіяною в поточному сезоні культурою. Відома середня врожайність кожної з оброблюваних культур, а також перелік внесених на кожну ділянку в цьому сезоні добрив.

Для кожної культури відомо: назва, врожайність по ділянках, чи потрібне для неї зрошення, які потрібні добрива.

Кожну ділянку обслуговує одна бригада, але будь-яка бригада може обслуговувати більше однієї ділянки.

Бригада має унікальний номер і характеризується: П.І.Б. бригадира, П.І.Б. працівників, кількістю одиниць кожного виду сільгосптехніки. Про кожного працівника відомо, якими видами сільгоспмашин він може керувати.

---

### 2. ER-модель (сутності та зв'язки)

#### 2.1 Сутності

| Назва сутності | Призначення |
|----------------|-------------|
| BRIGADE | Інформація про робочі бригади |
| CROP | Довідник сільськогосподарських культур |
| FERTILIZER | Довідник добрив |
| LAND_PLOT | Земельні ділянки |
| WORKER | Працівники ферми |
| EQUIPMENT | Сільськогосподарська техніка |
| WORKER_EQUIPMENT_SKILL | Навички працівників (М:М) |
| FERTILIZER_APPLICATION | Внесення добрив (М:М) |

#### 2.2 Зв'язки між сутностями

| Батьківська сутність | Дочірня сутність | Тип зв'язку |
|----------------------|-------------------|-------------|
| BRIGADE | WORKER | 1 до багатьох |
| BRIGADE | EQUIPMENT | 1 до багатьох |
| BRIGADE | LAND_PLOT | 1 до багатьох |
| CROP | LAND_PLOT | 1 до багатьох |
| WORKER | WORKER_EQUIPMENT_SKILL | 1 до багатьох |
| EQUIPMENT | WORKER_EQUIPMENT_SKILL | 1 до багатьох |
| LAND_PLOT | FERTILIZER_APPLICATION | 1 до багатьох |
| FERTILIZER | FERTILIZER_APPLICATION | 1 до багатьох |
| WORKER | FERTILIZER_APPLICATION | 1 до багатьох |
| BRIGADE | FERTILIZER_APPLICATION | 1 до багатьох |

---

### 3. Фізична модель бази даних

#### 3.1 Загальна інформація

| Параметр | Значення |
|----------|----------|
| Назва бази даних | Farm_Management_Shevchenko |
| СУБД | Microsoft SQL Server |
| Кількість таблиць | 8 |
| Рівень нормалізації | 3NF |

#### 3.2 Структура таблиць

**Таблиця BRIGADE**

| Колонка | Тип даних | Обмеження |
|---------|-----------|-----------|
| brigade_id | INT | PRIMARY KEY |
| foreman_first_name | VARCHAR(50) | NOT NULL |
| foreman_last_name | VARCHAR(50) | NOT NULL |
| foreman_patronymic | VARCHAR(50) | NULL |
| formation_date | DATE | NULL |

**Таблиця CROP**

| Колонка | Тип даних | Обмеження |
|---------|-----------|-----------|
| crop_id | INT | PRIMARY KEY |
| crop_name | VARCHAR(100) | UNIQUE, NOT NULL |
| average_yield | DECIMAL(10,2) | NOT NULL |
| requires_irrigation | BIT | NOT NULL |
| growing_season_days | INT | NULL |

**Таблиця FERTILIZER**

| Колонка | Тип даних | Обмеження |
|---------|-----------|-----------|
| fertilizer_id | INT | PRIMARY KEY |
| fertilizer_name | VARCHAR(100) | UNIQUE, NOT NULL |
| fertilizer_type | VARCHAR(50) | NOT NULL |
| nitrogen_percent | DECIMAL(5,2) | NULL |
| phosphorus_percent | DECIMAL(5,2) | NULL |
| potassium_percent | DECIMAL(5,2) | NULL |
| application_rate | DECIMAL(10,2) | NULL |

**Таблиця LAND_PLOT**

| Колонка | Тип даних | Обмеження |
|---------|-----------|-----------|
| plot_id | INT | PRIMARY KEY |
| area | DECIMAL(10,2) | NOT NULL |
| has_irrigation | BIT | NOT NULL |
| soil_quality_index | DECIMAL(3,1) | NULL |
| brigade_id | INT | FOREIGN KEY (BRIGADE) |
| crop_id | INT | FOREIGN KEY (CROP) |

**Таблиця WORKER**

| Колонка | Тип даних | Обмеження |
|---------|-----------|-----------|
| worker_id | INT | PRIMARY KEY |
| first_name | VARCHAR(50) | NOT NULL |
| last_name | VARCHAR(50) | NOT NULL |
| patronymic | VARCHAR(50) | NULL |
| hire_date | DATE | NOT NULL |
| phone_number | VARCHAR(20) | NULL |
| brigade_id | INT | FOREIGN KEY (BRIGADE) |

**Таблиця EQUIPMENT**

| Колонка | Тип даних | Обмеження |
|---------|-----------|-----------|
| equipment_id | INT | PRIMARY KEY |
| equipment_type | VARCHAR(50) | NOT NULL |
| model | VARCHAR(100) | NOT NULL |
| manufacture_year | INT | NULL |
| purchase_date | DATE | NULL |
| status | VARCHAR(20) | NULL |
| brigade_id | INT | FOREIGN KEY (BRIGADE) |

**Таблиця WORKER_EQUIPMENT_SKILL**

| Колонка | Тип даних | Обмеження |
|---------|-----------|-----------|
| skill_id | INT | PRIMARY KEY |
| worker_id | INT | FOREIGN KEY (WORKER) |
| equipment_id | INT | FOREIGN KEY (EQUIPMENT) |
| skill_level | VARCHAR(20) | NULL |
| certification_date | DATE | NULL |
| experience_years | INT | NULL |

**Таблиця FERTILIZER_APPLICATION**

| Колонка | Тип даних | Обмеження |
|---------|-----------|-----------|
| application_id | INT | PRIMARY KEY |
| plot_id | INT | FOREIGN KEY (LAND_PLOT) |
| fertilizer_id | INT | FOREIGN KEY (FERTILIZER) |
| worker_id | INT | FOREIGN KEY (WORKER) |
| brigade_id | INT | FOREIGN KEY (BRIGADE) |
| application_date | DATE | NOT NULL |
| amount_kg | DECIMAL(10,2) | NOT NULL |
| application_method | VARCHAR(50) | NULL |
| notes | VARCHAR(500) | NULL |

---

### 4. Статистика наповнення таблиць

| Таблиця | Кількість записів |
|---------|-------------------|
| BRIGADE | 50 |
| CROP | 100 |
| FERTILIZER | 200 |
| LAND_PLOT | 1000 |
| WORKER | 2000 |
| EQUIPMENT | 500 |
| WORKER_EQUIPMENT_SKILL | 3000 |
| FERTILIZER_APPLICATION | 5000 |
| **ВСЬОГО** | **11850** |

---

### 5. Посилання на файли скриптів

| Файл | Призначення |
|------|-------------|
| SETUP.SQL | Створення таблиць та структури бази даних |
| INSERT.SQL | Наповнення таблиць тестовими даними |
| DELETE.SQL | Очищення та видалення всіх таблиць |

---

### ВИСНОВКИ

У ході виконання практичної роботи було створено фізичну модель бази даних для фермерського господарства у СУБД Microsoft SQL Server. База даних складається з 8 таблиць, які знаходяться у третій нормальній формі. Розроблено скрипти для створення структури (SETUP.SQL), наповнення даними (INSERT.SQL) та видалення об'єктів (DELETE.SQL). Таблиці наповнено тестовими даними у кількості понад 1000 записів у кожній, загальна кількість записів склала 11850. Створена база даних повністю відповідає вимогам предметної області та підтримує цілісність даних через механізм зовнішніх ключів.
