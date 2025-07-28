--Уникальные пользователи за весь период 
SELECT 
    count(DISTINCT visitor_id) AS visitors_count
FROM sessions;

--Уникальные пользователи по дням
SELECT
    TO_CHAR(visit_date, 'YYYY-MM-DD') AS v_date,
    COUNT(DISTINCT visitor_id) AS visitors_count
FROM sessions
GROUP BY v_date;




-- Какие каналы приводят пользователей (по дням/неделям/месяцам)
SELECT
    DATE_TRUNC('day', visit_date) AS day,
    LOWER(source) AS utm_source,
    LOWER(medium) AS utm_medium,
    COUNT(DISTINCT visitor_id) AS visitors_count
FROM sessions
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

SELECT
    DATE_TRUNC('week', visit_date) AS week,
    LOWER(source) AS utm_source,
    LOWER(medium) AS utm_medium,
    COUNT(DISTINCT visitor_id) AS visitors_count
FROM sessions
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

SELECT
    DATE_TRUNC('month', visit_date) AS month,
    LOWER(source) AS utm_source,
    LOWER(medium) AS utm_medium,
    COUNT(DISTINCT visitor_id) AS visitors_count
FROM sessions
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;






-- Сколько лидов приходит 
SELECT 
    count(DISTINCT lead_id) AS leads_count
FROM leads;

-- Сколько лидов приходит по дням
SELECT
    TO_CHAR(created_at, 'YYYY-MM-DD') AS created_date,
    COUNT(DISTINCT lead_id) AS lead_count
FROM leads
GROUP BY created_date;







-- Количество посещений по платным каналам 
SELECT
    to_char(visit_date, 'yyyy-mm-dd')::date AS visit_day,
    source,
    medium,
    campaign,
    count(DISTINCT visitor_id) AS visitors_count
FROM sessions
WHERE medium != 'organic'
GROUP BY to_char(visit_date, 'yyyy-mm-dd')::date, source, medium, campaign
ORDER BY visit_day ASC, visitors_count DESC;


--Расходы по каналам в динамике (по датам)
SELECT 
    campaign_date,
    utm_source,
    SUM(daily_spent) AS total_spent
FROM (
    SELECT campaign_date, utm_source, daily_spent FROM ya_ads
    UNION ALL
    SELECT campaign_date, utm_source, daily_spent FROM vk_ads
) AS all_ads
GROUP BY campaign_date, utm_source
ORDER BY campaign_date, utm_source;


--ОКУПАЮТСЯ ЛИ КАНАЛЫ?


-- Расходы по источникам
SELECT 
    utm_source, 
    SUM(daily_spent) AS total_spent
FROM (
        SELECT utm_source, daily_spent FROM ya_ads
        UNION ALL
        SELECT utm_source, daily_spent FROM vk_ads
) AS ads
GROUP BY 1;

-- Доходы по источникам
SELECT
    CASE
        WHEN LOWER(s.source) LIKE '%vk%' THEN 'vk'
        WHEN LOWER(s.source) LIKE '%ya%' OR LOWER(s.source) LIKE '%yandex%' THEN 'yandex'
    END AS utm_source,
    SUM(l.amount) AS total_revenue
FROM sessions s
JOIN leads l ON s.visitor_id = l.visitor_id
WHERE 
    (LOWER(s.source) LIKE '%vk%' OR LOWER(s.source) LIKE '%ya%' OR LOWER(s.source) LIKE '%yandex%')
    AND (l.status_id = 142 OR l.closing_reason = 'Успешно реализовано')
GROUP BY utm_source;

-- roi = (revenue - total_cost) / total_cost * 100%
roi = (8752676 - 6428804)/6428804 * 100 = 36,15%
roi vk=(2196731 - 745006)/745006 * 100 = ROI ≈ 194.86%
roi yandex=(6555945 - 5683798)/5683798 * 100 = ROI ≈ 15.34%





/*cpu = total_cost / visitors_count
cpl = total_cost / leads_count
cppu = total_cost / purchases_count
roi = (revenue - total_cost) / total_cost * 100%*/

--CPU

SELECT 
    SUM(daily_spent) AS total_cost
FROM (
    SELECT daily_spent FROM ya_ads
    UNION ALL
    SELECT daily_spent FROM vk_ads
) AS all_ads;

SELECT 
    count(DISTINCT visitor_id) AS visitors_count
FROM sessions

6428804/169140=38,03

--CPL

SELECT 
    SUM(daily_spent) AS total_cost
FROM (
    SELECT daily_spent FROM ya_ads
    UNION ALL
    SELECT daily_spent FROM vk_ads
) AS all_ads;

SELECT 
    count(DISTINCT lead_id) AS leads_count
FROM leads;

6428804/1300=4.945 или 4.95k

--CPPU

SELECT 
    SUM(daily_spent) AS total_cost
FROM (
    SELECT daily_spent FROM ya_ads
    UNION ALL
    SELECT daily_spent FROM vk_ads
) AS all_ads;

SELECT
    COUNT(DISTINCT lead_id) AS purchases_count
FROM leads
WHERE closing_reason = 'Успешно реализовано'
   OR status_id = 142;

6428804/205=31.360

-- roi = (revenue - total_cost) / total_cost * 100%


roi = (8752676 - 6428804)/6428804 * 100 = 36,15%
roi vk=(2196731 - 745006)/745006 * 100 = ROI ≈ 194.86%
roi yandex=(6555945 - 5683798)/5683798 * 100 = ROI ≈ 15.34%



-- По utm_sourse
SELECT
    s.source AS utm_source,
    COUNT(DISTINCT l.lead_id) AS purchases_count
FROM leads l
JOIN sessions s ON l.visitor_id = s.visitor_id
WHERE l.closing_reason = 'Успешно реализовано'
   OR l.status_id = 142
GROUP BY s.source
ORDER BY purchases_count DESC;
