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

--Количество уникальных пользователей для разных каналов (июнь):
SELECT
  LOWER(source) AS utm_source,
  COUNT(DISTINCT visitor_id) AS unique_visitors
FROM sessions
GROUP BY LOWER(source)
ORDER BY unique_visitors DESC;


-- Количество уникальных пользователей вк
SELECT 
COUNT(DISTINCT visitor_id) AS unique_vk_visitors
FROM sessions
WHERE LOWER(source) = 'vk';

--Количество уникальных пользователей yandex
SELECT 
COUNT(DISTINCT visitor_id) AS unique_yandex_visitors
FROM sessions
WHERE LOWER(source) = 'yandex';



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






-- Сколько лидов приходит в общем 
SELECT 
    count(DISTINCT lead_id) AS leads_count
FROM leads;



-- Сколько лидов приходит по дням
SELECT
    TO_CHAR(created_at, 'YYYY-MM-DD') AS created_date,
    COUNT(DISTINCT lead_id) AS lead_count
FROM leads
GROUP BY created_date;

--Сколько лидов приходит для Вк и Яндекс ???
SELECT
    LOWER(s.source) AS utm_source,
    COUNT(DISTINCT l.lead_id) AS leads_count
FROM leads l
JOIN sessions s ON l.visitor_id = s.visitor_id
WHERE LOWER(s.source) IN ('vk', 'yandex')
GROUP BY LOWER(s.source)
ORDER BY leads_count DESC;


--КОНВЕРСИЯ ИЗ КЛИКА В ЛИД

WITH sessions_with_leads AS (
    SELECT DISTINCT l.lead_id, l.visitor_id
    FROM leads l
    JOIN sessions s
        ON s.visitor_id = l.visitor_id
       AND s.visit_date <= l.created_at
)

SELECT
    (SELECT COUNT(DISTINCT visitor_id) FROM sessions) AS total_visitors,
    COUNT(DISTINCT lead_id) AS leads_after_session,
    ROUND(
        COUNT(DISTINCT lead_id) * 100.0 / (SELECT COUNT(DISTINCT visitor_id) FROM sessions),
        2
    ) AS conversion_to_lead_percent
FROM leads;




--КОНВЕРСИЯ ИЗ ЛИДА В ОПЛАТУ 

SELECT
    COUNT(DISTINCT lead_id) AS total_leads,
    COUNT(DISTINCT lead_id) FILTER (
        WHERE closing_reason = 'Успешная продажа'
    ) AS successful_clients,
    ROUND(
        COUNT(DISTINCT lead_id) FILTER (
            WHERE closing_reason = 'Успешная продажа'
        ) * 100.0 / COUNT(DISTINCT lead_id),
        2
    ) AS conversion_to_payment_percent
FROM leads;


-- Количество посещений по платным каналам (visits_count_source_no_organic)
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


--Расходы по всем источникам 



--Доходы по всем источникам

SELECT
    LOWER(s.source) AS utm_source,
    SUM(l.amount) AS total_revenue
FROM sessions s
JOIN leads l ON s.visitor_id = l.visitor_id
WHERE l.status_id = 142 OR l.closing_reason = 'Успешно реализовано'
GROUP BY LOWER(s.source)
ORDER BY total_revenue DESC;



-- Расходы по источникам вк и яндекс (остальные источники органические)
SELECT 
    utm_source, 
    SUM(daily_spent) AS total_spent
FROM (
        SELECT utm_source, daily_spent FROM ya_ads
        UNION ALL
        SELECT utm_source, daily_spent FROM vk_ads
) AS ads
GROUP BY 1;

-- Доходы по источникам вк и яндекс
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
roi общий по платным источникам = (8752676 - 6428804)/6428804 * 100 = 36,15%
roi vk=(2196731 - 745006)/745006 * 100 = ROI ≈ 194.86%
roi yandex=(6555945 - 5683798)/5683798 * 100 = ROI ≈ 15.34%




/*cpu (стоимость привлечения 1 пользователя)= total_cost / visitors_count
cpl (стоимость привлечения одного потенциального клиента (лида))= total_cost / leads_count
cppu (стоимость привлечения 1 покупателя) = total_cost / purchases_count
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

Для вк = 47,3
Для яндекс = 307,3

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

Для вк = 12 119
Для яндекс = 1930

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

Для вк = 81 197
Для яндекс = 26 607




-- roi = (revenue - total_cost) / total_cost * 100%


roi = (8752676 - 6428804)/6428804 * 100 = 36,15%
roi vk=(2196731 - 745006)/745006 * 100 = ROI ≈ 194.86%
roi yandex=(6555945 - 5683798)/5683798 * 100 = ROI ≈ 15.34%



-- Покупатели по каналам
SELECT
    s.source AS utm_source,
    COUNT(DISTINCT l.lead_id) AS purchases_count
FROM leads l
JOIN sessions s ON l.visitor_id = s.visitor_id
WHERE l.closing_reason = 'Успешно реализовано'
   OR l.status_id = 142
GROUP BY s.source

ORDER BY purchases_count DESC;
