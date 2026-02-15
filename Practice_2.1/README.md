# Практична робота №1: CASE-засоби моделювання бізнес-процесів ІС, методологія IDEF3 та DFD

**Виконала:** Шевченко А. А.  
**Група:** КС-21  
**Спеціальність:** 122 «Комп’ютерні науки»  
**Дата:** 2025  
**Інструменти:** MS SQL Server, T-SQL, draw.io (ER-діаграми)

---

## Мета роботи
Ознайомитися з основними операціями створення, редагування та видалення таблиць у базі даних. Розробити логічну та фізичну моделі для автоматизації обліку фермерського господарства, реалізувати структуру БД та виконати аналітичні запити.

---

## Постановка задачі
Спроєктувати базу даних для фермерського господарства, яке містить:
- ділянки землі (площа, наявність зрошення, посіяна культура);
- культури (назва, врожайність, потреба у зрошенні та добривах);
- бригади (бригадир, працівники, техніка);
- працівники (П.І.Б., навички керування технікою);
- добрива та їх внесення на ділянки.

**Запити:**
- площа під культури;
- робітники бригади з технікою;
- культура з максимальною врожайністю;
- бригади з технікою понад середню;
- ділянки з невідповідними добривами.

**Транзакції:**
- придбання техніки;
- наймання/звільнення працівників.

---

## Виконані завдання

### Завдання 1. Тестування (SQL Server)
Підключено екземпляр SQL Server, створено БД, виконано початкові скрипти (`SETUP.SQL`), перевірено структуру таблиць.

### Завдання 2. Логічна та фізична моделі

#### Логічна модель (ER-діаграма)
Основні сутності:
- **Brigade** – бригади
- **Land_Plot** – ділянки
- **Crop** – культури
- **Fertilizer** – добрива
- **Fertilizer_Application** – внесення добрив
- **Worker** – працівники
- **Equipment** – техніка
- **Worker_Equipment_Skill** – навички керування технікою

Зв’язки:
- `Brigade` – `Land_Plot` (1:M)
- `Brigade` – `Worker` (1:M)
- `Land_Plot` – `Crop` (M:1)
- `Land_Plot` – `Fertilizer_Application` (1:M)
- `Fertilizer` – `Fertilizer_Application` (1:M)
- `Worker` – `Fertilizer_Application` (1:M)
- `Worker` – `Worker_Equipment_Skill` (1:M)
- `Equipment` – `Worker_Equipment_Skill` (1:M)

#### Фізична модель (T-SQL)
Таблиці створено з урахуванням:
- первинних ключів (`IDENTITY`);
- зовнішніх ключів (`REFERENCES`);
- обмежень (`CHECK`, `UNIQUE`);
- нормалізації до 3НФ.

**Приклад створення таблиці:**
```sql
CREATE TABLE Brigade (
    brigade_id INT IDENTITY(1,1) PRIMARY KEY,
    foreman_first_name NVARCHAR(50) NOT NULL,
    foreman_last_name NVARCHAR(50) NOT NULL,
    foreman_patronymic NVARCHAR(50),
    formation_date DATE NOT NULL
);
```

---

### Завдання 3. Реалізація та запити

#### Підключення до БД
![Підключення до SQL Server](./screenshots/connect.png)

#### Структура таблиць
![Таблиці після SETUP.SQL](./screenshots/tables.png)

#### Вставка даних (INSERT)
![INSERT](./screenshots/insert.png)

#### Модифікація структури
![ALTER TABLE](./screenshots/alter.png)

#### Видалення та очищення
![DELETE та TRUNCATE](./screenshots/delete.png)

---

### Аналітичні запити

#### 1. Площа під культури
```sql
SELECT Crop.crop_name, SUM(Land_Plot.area) AS total_area
FROM Land_Plot
JOIN Crop ON Land_Plot.crop_id = Crop.crop_id
GROUP BY Crop.crop_name;
```
![Запит 1](./screenshots/query1.png)

#### 2. Робітники бригади з технікою
```sql
SELECT Worker.last_name, Equipment.model
FROM Worker
JOIN Worker_Equipment_Skill ON Worker.worker_id = Worker_Equipment_Skill.worker_id
JOIN Equipment ON Worker_Equipment_Skill.equipment_id = Equipment.equipment_id
ORDER BY Worker.last_name;
```
![Запит 2](./screenshots/query2.png)

#### 3. Культура з максимальною врожайністю
```sql
SELECT TOP 1 crop_name, average_yield
FROM Crop
ORDER BY average_yield DESC;
```
![Запит 3](./screenshots/query3.png)

#### 4. Бригади з технікою понад середню
```sql
SELECT Brigade.brigade_id, COUNT(Equipment.equipment_id) AS tech_count
FROM Brigade
JOIN Worker ON Brigade.brigade_id = Worker.brigade_id
JOIN Worker_Equipment_Skill ON Worker.worker_id = Worker_Equipment_Skill.worker_id
JOIN Equipment ON Worker_Equipment_Skill.equipment_id = Equipment.equipment_id
GROUP BY Brigade.brigade_id
HAVING COUNT(Equipment.equipment_id) > (
    SELECT AVG(tech_count) FROM (
        SELECT COUNT(Equipment.equipment_id) AS tech_count
        FROM Brigade
        JOIN Worker ON Brigade.brigade_id = Worker.brigade_id
        JOIN Worker_Equipment_Skill ON Worker.worker_id = Worker_Equipment_Skill.worker_id
        JOIN Equipment ON Worker_Equipment_Skill.equipment_id = Equipment.equipment_id
        GROUP BY Brigade.brigade_id
    ) AS sub
);
```
![Запит 4](./screenshots/query4.png)

#### 5. Ділянки з невідповідними добривами
```sql
SELECT Land_Plot.plot_id, Crop.crop_name, Fertilizer.fertilizer_name
FROM Land_Plot
JOIN Crop ON Land_plot.crop_id = Crop.crop_id
JOIN Fertilizer_Application ON Land_Plot.plot_id = Fertilizer_Application.plot_id
JOIN Fertilizer ON Fertilizer_Application.fertilizer_id = Fertilizer.fertilizer_id
WHERE Fertilizer.fertilizer_type NOT IN (
    SELECT required_fertilizer_type
    FROM Crop_Required_Fertilizer
    WHERE Crop_Required_Fertilizer.crop_id = Crop.crop_id
);
```
![Запит 5](./screenshots/query5.png)

---

## Висновки
У ході виконання практичної роботи було:
- спроєктовано логічну модель фермерської БД у вигляді ER-діаграми;
- створено фізичну модель із дотриманням 3НФ та посилальної цілісності;
- реалізовано набір T-SQL скриптів: створення (`SETUP.SQL`), наповнення (`INSERT.SQL`), модифікація (`UPDATE.SQL`) та аналітичні запити (`QUERY.SQL`);
- виконано тестування в MS SQL Server;
- закріплено навички DDL, DML, транзакцій та складних запитів.
