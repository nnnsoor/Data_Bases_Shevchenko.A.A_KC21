USE Farm_Management_Shevchenko;
GO

-- ============================================================
-- «¿¬ƒ¿ÕÕﬂ 4: WHERE
-- ============================================================

SELECT plot_id, area, soil_quality_index
FROM LAND_PLOT
WHERE area > 50;

SELECT crop_id, crop_name, average_yield
FROM CROP
WHERE average_yield > 30;

SELECT worker_id, first_name, last_name, hire_date
FROM WORKER
WHERE hire_date > '2018-01-01';

SELECT equipment_id, equipment_type, model, manufacture_year
FROM EQUIPMENT
WHERE manufacture_year >= 2019;

SELECT application_id, plot_id, fertilizer_id, amount_kg
FROM FERTILIZER_APPLICATION
WHERE amount_kg > 200;

-- ============================================================
-- «¿¬ƒ¿ÕÕﬂ 5: AND, OR, NOT
-- ============================================================

SELECT plot_id, area, has_irrigation, soil_quality_index
FROM LAND_PLOT
WHERE has_irrigation = 1 AND area > 40;

SELECT crop_id, crop_name, average_yield, requires_irrigation
FROM CROP
WHERE requires_irrigation = 1 OR average_yield > 50;

SELECT worker_id, first_name, last_name, brigade_id
FROM WORKER
WHERE brigade_id IN (1, 2, 3) AND hire_date < '2016-01-01';

SELECT equipment_id, equipment_type, model, status
FROM EQUIPMENT
WHERE status = '¿ÍÚË‚ÌËÈ' AND equipment_type = '“‡ÍÚÓ';

SELECT application_id, plot_id, amount_kg, application_method
FROM FERTILIZER_APPLICATION
WHERE NOT application_method = '–ÓÁÒ≥‚' AND amount_kg >= 100;

-- ============================================================
-- «¿¬ƒ¿ÕÕﬂ 6: LIKE
-- ============================================================

SELECT crop_id, crop_name
FROM CROP
WHERE crop_name LIKE '%ÓÁËÏ%';

SELECT worker_id, first_name, last_name, phone_number
FROM WORKER
WHERE phone_number LIKE '+38050%';

SELECT equipment_id, equipment_type, model
FROM EQUIPMENT
WHERE model LIKE 'John Deere%';

SELECT fertilizer_id, fertilizer_name, fertilizer_type
FROM FERTILIZER
WHERE fertilizer_type LIKE '%ÌÂ';

SELECT worker_id, first_name, last_name, patronymic
FROM WORKER
WHERE patronymic LIKE '%Ó‚Ë˜';

-- ============================================================
-- «¿¬ƒ¿ÕÕﬂ 7: JOIN (INNER JOIN)
-- ============================================================

SELECT lp.plot_id, lp.area, c.crop_name, c.average_yield
FROM LAND_PLOT lp
INNER JOIN CROP c ON lp.crop_id = c.crop_id;

SELECT w.worker_id, w.first_name, w.last_name, b.foreman_last_name AS brigade_foreman
FROM WORKER w
INNER JOIN BRIGADE b ON w.brigade_id = b.brigade_id;

SELECT fa.application_id, lp.plot_id, f.fertilizer_name, fa.amount_kg, fa.application_date
FROM FERTILIZER_APPLICATION fa
INNER JOIN LAND_PLOT lp ON fa.plot_id = lp.plot_id
INNER JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id;

SELECT wes.skill_id, w.first_name, w.last_name, e.equipment_type, e.model, wes.skill_level
FROM WORKER_EQUIPMENT_SKILL wes
INNER JOIN WORKER w ON wes.worker_id = w.worker_id
INNER JOIN EQUIPMENT e ON wes.equipment_id = e.equipment_id;

SELECT e.equipment_id, e.equipment_type, e.model, b.foreman_first_name, b.foreman_last_name
FROM EQUIPMENT e
INNER JOIN BRIGADE b ON e.brigade_id = b.brigade_id;

-- ============================================================
-- «¿¬ƒ¿ÕÕﬂ 8: LEFT JOIN, RIGHT JOIN, FULL JOIN
-- ============================================================

SELECT c.crop_id, c.crop_name, lp.plot_id, lp.area
FROM CROP c
LEFT JOIN LAND_PLOT lp ON c.crop_id = lp.crop_id;

SELECT w.worker_id, w.first_name, w.last_name, wes.equipment_id, wes.skill_level
FROM WORKER w
LEFT JOIN WORKER_EQUIPMENT_SKILL wes ON w.worker_id = wes.worker_id;

SELECT b.brigade_id, b.foreman_last_name, e.equipment_id, e.equipment_type
FROM EQUIPMENT e
RIGHT JOIN BRIGADE b ON e.brigade_id = b.brigade_id;

SELECT lp.plot_id, lp.area, fa.fertilizer_id, fa.amount_kg
FROM LAND_PLOT lp
LEFT JOIN FERTILIZER_APPLICATION fa ON lp.plot_id = fa.plot_id;

SELECT f.fertilizer_id, f.fertilizer_name, fa.plot_id, fa.application_date
FROM FERTILIZER f
FULL JOIN FERTILIZER_APPLICATION fa ON f.fertilizer_id = fa.fertilizer_id;

-- ============================================================
-- «¿¬ƒ¿ÕÕﬂ 9: SUBQUERY
-- ============================================================

SELECT crop_id, crop_name, average_yield
FROM CROP
WHERE average_yield = (SELECT MAX(average_yield) FROM CROP);

SELECT plot_id, area, brigade_id
FROM LAND_PLOT
WHERE brigade_id IN (
    SELECT brigade_id FROM BRIGADE
    WHERE foreman_last_name LIKE ' %'
);

SELECT worker_id, first_name, last_name
FROM WORKER
WHERE worker_id IN (
    SELECT worker_id FROM WORKER_EQUIPMENT_SKILL
    WHERE skill_level = '≈ÍÒÔÂÚ'
);

SELECT plot_id, area, crop_id
FROM LAND_PLOT
WHERE area > (SELECT AVG(area) FROM LAND_PLOT);

SELECT equipment_id, equipment_type, model
FROM EQUIPMENT
WHERE brigade_id IN (
    SELECT brigade_id FROM LAND_PLOT
    WHERE has_irrigation = 1
);

-- ============================================================
-- «¿¬ƒ¿ÕÕﬂ 10: GROUP BY + HAVING + JOIN
-- ============================================================

SELECT c.crop_name, SUM(lp.area) AS total_area
FROM LAND_PLOT lp
INNER JOIN CROP c ON lp.crop_id = c.crop_id
GROUP BY c.crop_name
HAVING SUM(lp.area) > 50;

SELECT b.brigade_id, b.foreman_last_name, COUNT(w.worker_id) AS worker_count
FROM BRIGADE b
INNER JOIN WORKER w ON b.brigade_id = w.brigade_id
GROUP BY b.brigade_id, b.foreman_last_name
HAVING COUNT(w.worker_id) > 5;

SELECT b.brigade_id, b.foreman_last_name, COUNT(e.equipment_id) AS equipment_count
FROM BRIGADE b
INNER JOIN EQUIPMENT e ON b.brigade_id = e.brigade_id
GROUP BY b.brigade_id, b.foreman_last_name
HAVING COUNT(e.equipment_id) > (
    SELECT AVG(cnt) FROM (
        SELECT COUNT(equipment_id) AS cnt FROM EQUIPMENT GROUP BY brigade_id
    ) t
);

SELECT f.fertilizer_name, SUM(fa.amount_kg) AS total_applied
FROM FERTILIZER_APPLICATION fa
INNER JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id
GROUP BY f.fertilizer_name
HAVING SUM(fa.amount_kg) > 500;

SELECT e.equipment_type, COUNT(wes.skill_id) AS certified_workers
FROM EQUIPMENT e
INNER JOIN WORKER_EQUIPMENT_SKILL wes ON e.equipment_id = wes.equipment_id
GROUP BY e.equipment_type
HAVING COUNT(wes.skill_id) >= 5;

-- ============================================================
-- «¿¬ƒ¿ÕÕﬂ 11: — À¿ƒÕ≤ ¡¿√¿“Œ“¿¡À»◊Õ≤ «¿œ»“»
-- ============================================================

SELECT b.brigade_id, b.foreman_first_name, b.foreman_last_name,
       COUNT(DISTINCT w.worker_id) AS workers,
       COUNT(DISTINCT e.equipment_id) AS equipment,
       COUNT(DISTINCT lp.plot_id) AS plots,
       SUM(lp.area) AS total_area
FROM BRIGADE b
LEFT JOIN WORKER w ON b.brigade_id = w.brigade_id
LEFT JOIN EQUIPMENT e ON b.brigade_id = e.brigade_id
LEFT JOIN LAND_PLOT lp ON b.brigade_id = lp.brigade_id
GROUP BY b.brigade_id, b.foreman_first_name, b.foreman_last_name;

SELECT c.crop_name, COUNT(lp.plot_id) AS plot_count,
       SUM(lp.area) AS total_area,
       AVG(lp.soil_quality_index) AS avg_soil_quality,
       c.average_yield,
       SUM(lp.area) * c.average_yield AS estimated_total_harvest
FROM CROP c
INNER JOIN LAND_PLOT lp ON c.crop_id = lp.crop_id
GROUP BY c.crop_name, c.average_yield
ORDER BY estimated_total_harvest DESC;

SELECT w.worker_id, w.first_name, w.last_name,
       b.foreman_last_name AS brigade,
       COUNT(wes.skill_id) AS skill_count,
       MAX(wes.experience_years) AS max_experience,
       STUFF((
           SELECT ', ' + e2.equipment_type
           FROM WORKER_EQUIPMENT_SKILL wes2
           INNER JOIN EQUIPMENT e2 ON wes2.equipment_id = e2.equipment_id
           WHERE wes2.worker_id = w.worker_id
           FOR XML PATH('')
       ), 1, 2, '') AS equipment_types
FROM WORKER w
INNER JOIN BRIGADE b ON w.brigade_id = b.brigade_id
INNER JOIN WORKER_EQUIPMENT_SKILL wes ON w.worker_id = wes.worker_id
INNER JOIN EQUIPMENT e ON wes.equipment_id = e.equipment_id
GROUP BY w.worker_id, w.first_name, w.last_name, b.foreman_last_name
HAVING COUNT(wes.skill_id) > 1;

SELECT lp.plot_id, lp.area, c.crop_name,
       b.foreman_last_name AS brigade,
       SUM(fa.amount_kg) AS total_fertilizer_kg,
       COUNT(fa.application_id) AS application_count
FROM LAND_PLOT lp
INNER JOIN CROP c ON lp.crop_id = c.crop_id
INNER JOIN BRIGADE b ON lp.brigade_id = b.brigade_id
LEFT JOIN FERTILIZER_APPLICATION fa ON lp.plot_id = fa.plot_id
GROUP BY lp.plot_id, lp.area, c.crop_name, b.foreman_last_name
ORDER BY total_fertilizer_kg DESC;

SELECT f.fertilizer_type,
       COUNT(fa.application_id) AS applications,
       SUM(fa.amount_kg) AS total_kg,
       AVG(fa.amount_kg) AS avg_kg,
       COUNT(DISTINCT fa.plot_id) AS plots_covered
FROM FERTILIZER f
INNER JOIN FERTILIZER_APPLICATION fa ON f.fertilizer_id = fa.fertilizer_id
INNER JOIN LAND_PLOT lp ON fa.plot_id = lp.plot_id
GROUP BY f.fertilizer_type
ORDER BY total_kg DESC;

-- ============================================================
-- «¿¬ƒ¿ÕÕﬂ 12: WHERE + JOIN
-- ============================================================

SELECT lp.plot_id, lp.area, c.crop_name, c.requires_irrigation
FROM LAND_PLOT lp
INNER JOIN CROP c ON lp.crop_id = c.crop_id
WHERE c.requires_irrigation = 1 AND lp.has_irrigation = 0;

SELECT w.first_name, w.last_name, e.equipment_type, e.model, wes.skill_level
FROM WORKER w
INNER JOIN WORKER_EQUIPMENT_SKILL wes ON w.worker_id = wes.worker_id
INNER JOIN EQUIPMENT e ON wes.equipment_id = e.equipment_id
WHERE wes.skill_level = '≈ÍÒÔÂÚ' AND e.equipment_type = '“‡ÍÚÓ';

SELECT b.brigade_id, b.foreman_last_name,
       COUNT(e.equipment_id) AS equipment_count
FROM BRIGADE b
INNER JOIN EQUIPMENT e ON b.brigade_id = e.brigade_id
WHERE e.status = '¿ÍÚË‚ÌËÈ'
GROUP BY b.brigade_id, b.foreman_last_name
HAVING COUNT(e.equipment_id) > (
    SELECT AVG(cnt) FROM (
        SELECT COUNT(equipment_id) AS cnt
        FROM EQUIPMENT
        WHERE status = '¿ÍÚË‚ÌËÈ'
        GROUP BY brigade_id
    ) t
);

SELECT lp.plot_id, lp.area, c.crop_name, f.fertilizer_name, fa.amount_kg
FROM LAND_PLOT lp
INNER JOIN CROP c ON lp.crop_id = c.crop_id
INNER JOIN FERTILIZER_APPLICATION fa ON lp.plot_id = fa.plot_id
INNER JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id
WHERE lp.soil_quality_index < 7.0 AND fa.amount_kg > 150;

SELECT w.first_name, w.last_name, b.foreman_last_name AS brigade,
       fa.application_date, f.fertilizer_name, fa.amount_kg
FROM WORKER w
INNER JOIN FERTILIZER_APPLICATION fa ON w.worker_id = fa.worker_id
INNER JOIN FERTILIZER f ON fa.fertilizer_id = f.fertilizer_id
INNER JOIN BRIGADE b ON w.brigade_id = b.brigade_id
WHERE fa.application_date BETWEEN '2024-04-01' AND '2024-04-30'
ORDER BY fa.application_date;
GO