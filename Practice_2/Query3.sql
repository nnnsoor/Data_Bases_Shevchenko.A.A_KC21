USE Farm_Management_Shevchenko;
GO

SELECT
    plot_id            AS [Номер ділянки],
    area               AS [Площа (га)],
    has_irrigation     AS [Зрошення],
    soil_quality_index AS [Індекс якості ґрунту]
FROM LAND_PLOT
WHERE area > 100;
GO

SELECT
    plot_id            AS [Номер ділянки],
    area               AS [Площа (га)],
    has_irrigation     AS [Зрошення],
    soil_quality_index AS [Якість ґрунту]
FROM LAND_PLOT
WHERE (has_irrigation = 1 AND area > 150)
   OR soil_quality_index > 9.0;
GO

SELECT
    worker_id    AS [ID],
    last_name    AS [Прізвище],
    first_name   AS [Ім'я],
    patronymic   AS [По батькові],
    phone_number AS [Телефон]
FROM WORKER
WHERE last_name LIKE '%енко';
GO

SELECT
    lp.plot_id                                          AS [№ ділянки],
    lp.area                                             AS [Площа (га)],
    c.crop_name                                         AS [Культура],
    c.average_yield                                     AS [Врожайність (ц/га)],
    b.foreman_last_name + ' ' + b.foreman_first_name    AS [Бригадир]
FROM LAND_PLOT lp
INNER JOIN CROP    c ON lp.crop_id    = c.crop_id
INNER JOIN BRIGADE b ON lp.brigade_id = b.brigade_id;
GO

SELECT
    b.brigade_id                                            AS [№ бригади],
    b.foreman_last_name + ' ' + b.foreman_first_name       AS [Бригадир],
    lp.plot_id                                              AS [№ ділянки],
    lp.area                                                 AS [Площа (га)]
FROM BRIGADE b
LEFT JOIN LAND_PLOT lp ON b.brigade_id = lp.brigade_id
ORDER BY b.brigade_id;
GO

SELECT
    brigade_id                                          AS [№ бригади],
    foreman_last_name + ' ' + foreman_first_name        AS [Бригадир],
    formation_date                                      AS [Дата створення]
FROM BRIGADE
WHERE brigade_id IN (
    SELECT DISTINCT brigade_id
    FROM WORKER
    WHERE DATEDIFF(YEAR, hire_date, GETDATE()) > 5
);
GO

SELECT
    b.brigade_id                                            AS [№ бригади],
    b.foreman_last_name + ' ' + b.foreman_first_name       AS [Бригадир],
    COUNT(lp.plot_id)                                       AS [Кількість ділянок],
    SUM(lp.area)                                            AS [Загальна площа (га)],
    AVG(lp.area)                                            AS [Середня площа (га)]
FROM BRIGADE b
INNER JOIN LAND_PLOT lp ON b.brigade_id = lp.brigade_id
GROUP BY b.brigade_id, b.foreman_last_name, b.foreman_first_name
HAVING SUM(lp.area) > 200
ORDER BY SUM(lp.area) DESC;
GO

SELECT
    c.crop_name                                             AS [Культура],
    c.average_yield                                         AS [Врожайність (ц/га)],
    lp.plot_id                                              AS [№ ділянки],
    lp.area                                                 AS [Площа (га)],
    lp.has_irrigation                                       AS [Зрошення],
    b.foreman_last_name + ' ' + b.foreman_first_name        AS [Бригадир],
    COUNT(w.worker_id)                                      AS [Кількість працівників]
FROM CROP c
INNER JOIN LAND_PLOT lp ON c.crop_id     = lp.crop_id
INNER JOIN BRIGADE b    ON lp.brigade_id = b.brigade_id
LEFT  JOIN WORKER w     ON b.brigade_id  = w.brigade_id
WHERE c.average_yield = (SELECT MAX(average_yield) FROM CROP)
GROUP BY
    c.crop_name, c.average_yield,
    lp.plot_id, lp.area, lp.has_irrigation,
    b.foreman_last_name, b.foreman_first_name
ORDER BY lp.area DESC;
GO

SELECT
    fa.application_date                             AS [Дата внесення],
    lp.plot_id                                      AS [№ ділянки],
    lp.area                                         AS [Площа ділянки (га)],
    f.fertilizer_name                               AS [Добриво],
    f.fertilizer_type                               AS [Тип добрива],
    fa.amount_kg                                    AS [Кількість (кг)],
    fa.application_method                           AS [Спосіб внесення],
    w.last_name + ' ' + w.first_name                AS [Виконавець]
FROM FERTILIZER_APPLICATION fa
INNER JOIN LAND_PLOT  lp ON fa.plot_id       = lp.plot_id
INNER JOIN FERTILIZER  f ON fa.fertilizer_id = f.fertilizer_id
INNER JOIN WORKER      w ON fa.worker_id     = w.worker_id
WHERE lp.has_irrigation = 1
  AND fa.amount_kg > 150
ORDER BY fa.application_date;
GO