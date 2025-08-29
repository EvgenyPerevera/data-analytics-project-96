--Уникальные пользователи за весь период 
SELECT count(DISTINCT visitor_id) AS visitors_count
FROM sessions;

--Уникальные пользователи по дням
SELECT
    to_char(visit_date, 'YYYY-MM-DD') AS v_date,
    count(DISTINCT visitor_id) AS visitors_count
FROM sessions
GROUP BY v_date;

--Количество уникальных пользователей для разных каналов (июнь):
SELECT
    lower(source) AS utm_source,
    count(DISTINCT visitor_id) AS unique_visitors
FROM sessions
GROUP BY lower(source)
ORDER BY unique_visitors DESC;

--Количество уникальных пользователей VK
SELECT count(DISTINCT visitor_id) AS unique_vk_visitors
FROM sessions
WHERE lower(source) = 'vk';

--Количество уникальных пользователей Yandex
SELECT count(DISTINCT visitor_id) AS unique_yandex_visitors
FROM sessions
WHERE lower(source) = 'yandex';

--Какие каналы приводят пользователей (по дням/неделям/месяцам)
SELECT
    date_trunc('day', visit_date) AS visit_day,
    lower(source) AS utm_source,
    lower(medium) AS utm_medium,
    count(DISTINCT visitor_id) AS visitors_count
FROM sessions
GROUP BY visit_day, utm_source, utm_medium
ORDER BY visit_day, utm_source, utm_medium;

SELECT
    date_trunc('week', visit_date) AS visit_week,
    lower(source) AS utm_source,
    lower(medium) AS utm_medium,
    count(DISTINCT visitor_id) AS visitors_count
FROM sessions
GROUP BY visit_day, utm_source, utm_medium
ORDER BY visit_day, utm_source, utm_medium;

SELECT
    date_trunc('month', visit_date) AS visit_month,
    lower(source) AS utm_source,
    lower(medium) AS utm_medium,
    count(DISTINCT visitor_id) AS visitors_count
FROM sessions
GROUP BY visit_day, utm_source, utm_medium
ORDER BY visit_day, utm_source, utm_medium;

--Сколько лидов приходит в общем 
SELECT count(DISTINCT lead_id) AS leads_count
FROM leads;

--Сколько лидов приходит по дням
SELECT
    to_char(created_at, 'YYYY-MM-DD') AS created_date,
    count(DISTINCT lead_id) AS lead_count
FROM leads
GROUP BY created_date;

--Сколько лидов приходит для VK и Yandex?
SELECT
    lower(s.source) AS utm_source,
    count(DISTINCT l.lead_id) AS leads_count
FROM leads AS l
INNER JOIN sessions AS s ON l.visitor_id = s.visitor_id
WHERE lower(s.source) IN ('vk', 'yandex')
GROUP BY lower(s.source)
ORDER BY leads_count DESC;

--Конверсия Клик-Лид-продажа
WITH visitors_count AS (
    SELECT count(DISTINCT visitor_id) AS total_visitors
    FROM sessions
),

leads_stats AS (
    SELECT
        count(DISTINCT l.lead_id) AS total_leads,
        count(DISTINCT l.lead_id) FILTER (
            WHERE l.closing_reason = 'Успешная продажа'
        ) AS successful_sales
    FROM leads AS l
)

SELECT
    'Visitors' AS funnel_stage,
    v.total_visitors AS metric_value
FROM visitors_count AS v
UNION ALL
SELECT
    'Leads' AS funnel_stage,
    ls.total_leads AS metric_value
FROM leads_stats AS ls
UNION ALL
SELECT
    'Successful sales' AS funnel_stage,
    ls.successful_sales AS metric_value
FROM leads_stats AS ls;

--Конверсия Клик-Лид-Продажа для VK и Yandex 
WITH filtered_visitors AS (
    SELECT DISTINCT
        s.visitor_id,
        lower(s.source) AS channel
    FROM sessions AS s
    WHERE lower(s.source) IN ('vk', 'yandex')
),

leads_stats AS (
    SELECT
        f.channel,
        count(DISTINCT l.lead_id) AS total_leads,
        count(DISTINCT l.lead_id) FILTER (
            WHERE l.closing_reason = 'Успешная продажа'
        ) AS successful_sales
    FROM leads AS l
    INNER JOIN filtered_visitors AS f
        ON l.visitor_id = f.visitor_id
    GROUP BY f.channel
),

visitors_count AS (
    SELECT
        lower(source) AS channel,
        count(DISTINCT visitor_id) AS total_visitors
    FROM sessions
    WHERE lower(source) IN ('vk', 'yandex')
    GROUP BY lower(source)
),

funnel_raw AS (
    SELECT
        v.channel,
        'Visitors' AS funnel_stage,
        v.total_visitors AS metric_value
    FROM visitors_count AS v
    UNION ALL
    SELECT
        l.channel,
        'Leads' AS funnel_stage,
        l.total_leads AS metric_value
    FROM leads_stats AS l
    UNION ALL
    SELECT
        l.channel,
        'Successful sales' AS funnel_stage,
        l.successful_sales AS metric_value
    FROM leads_stats AS l
)

SELECT *
FROM funnel_raw
ORDER BY
    channel,
    CASE stage
        WHEN 'Visitors' THEN 1
        WHEN 'Leads' THEN 2
        WHEN 'Successful sales' THEN 3
    END;
END;

--Количество посещений по платным каналам
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

--Доходы по всем источникам
SELECT
    lower(s.source) AS utm_source,
    sum(l.amount) AS total_revenue
FROM sessions AS s
INNER JOIN leads AS l ON s.visitor_id = l.visitor_id
WHERE l.status_id = 142 OR l.closing_reason = 'Успешно реализовано'
GROUP BY lower(s.source)
ORDER BY total_revenue DESC;

--Доходы по источникам VK и Yandex
SELECT
    CASE
        WHEN lower(s.source) LIKE '%vk%' THEN 'vk'
        WHEN
            lower(s.source) LIKE '%ya%' OR lower(s.source) LIKE '%yandex%'
            THEN 'yandex'
    END AS utm_source,
    sum(l.amount) AS total_revenue
FROM sessions AS s
INNER JOIN leads AS l ON s.visitor_id = l.visitor_id
WHERE
    (
        lower(s.source) LIKE '%vk%'
        OR lower(s.source) LIKE '%ya%'
        OR lower(s.source) LIKE '%yandex%'
    )
    AND (l.status_id = 142 OR l.closing_reason = 'Успешно реализовано')
GROUP BY utm_source;

--Расходы по источникам VK и Yandex
SELECT
    utm_source,
    sum(daily_spent) AS total_spent
FROM (
    SELECT
        utm_source,
        daily_spent
    FROM ya_ads
    UNION ALL
    SELECT
        utm_source,
        daily_spent
    FROM vk_ads
) AS ads
GROUP BY utm_source;

--Расходы на VK и Yandex в динамике (по датам)
SELECT
    campaign_date,
    utm_source,
    sum(daily_spent) AS total_spent
FROM (
    SELECT
        campaign_date,
        utm_source,
        daily_spent
    FROM ya_ads
    UNION ALL
    SELECT
        campaign_date,
        utm_source,
        daily_spent
    FROM vk_ads
) AS all_ads
GROUP BY campaign_date, utm_source
ORDER BY campaign_date, utm_source;

/*ROI = (revenue - total_cost) / total_cost * 100%
ROI = (8752676 - 6428804)/6428804 * 100 = 36,15%
ROI VK=(2196731 - 745006)/745006 * 100 = ROI ≈ 194.86%
ROI Yandex=(6555945 - 5683798)/5683798 * 100 = ROI ≈ 15.34%*/

--CPU (стоимость 1 пользователя для VK и Yandex) = total_cost / visitors_count
SELECT sum(daily_spent) AS total_cost
FROM (
    SELECT daily_spent FROM ya_ads
    UNION ALL
    SELECT daily_spent FROM vk_ads
) AS all_ads;

SELECT count(DISTINCT visitor_id) AS visitors_count
FROM sessions;

--CPL (стоимость 1 лида для VK и Yandex) = total_cost / leads_count
SELECT sum(daily_spent) AS total_cost
FROM (
    SELECT daily_spent FROM ya_ads
    UNION ALL
    SELECT daily_spent FROM vk_ads
) AS all_ads;

SELECT count(DISTINCT lead_id) AS leads_count
FROM leads;

--CPPU (стоимость 1 покупателя для VK и Yandex) = total_cost / purchases_count
SELECT sum(daily_spent) AS total_cost
FROM (
    SELECT daily_spent FROM ya_ads
    UNION ALL
    SELECT daily_spent FROM vk_ads
) AS all_ads;

SELECT count(DISTINCT lead_id) AS purchases_count
FROM leads
WHERE
    closing_reason = 'Успешно реализовано'
    OR status_id = 142;

--Через сколько дней после перехода по рекламе закрывается 90% лидов?
WITH paid_sessions AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source,
        s.medium,
        row_number()
            OVER (
                PARTITION BY s.visitor_id
                ORDER BY s.visit_date DESC
            )
        AS rn
    FROM sessions AS s
    WHERE lower(s.medium) IN (
        'cpc',
        'cpm',
        'cpa',
        'cpp',
        'social',
        'tg',
        'youtube'
    )
),

last_paid_click AS (
    SELECT
        ps.visitor_id,
        ps.visit_date AS last_click_date,
        ps.source AS last_click_source
    FROM paid_sessions AS ps
    WHERE ps.rn = 1
),

lead_lags AS (
    SELECT
        l.lead_id,
        l.visitor_id,
        l.created_at,
        l.amount,
        l.status_id,
        l.closing_reason,
        lpc.last_click_date,
        lpc.last_click_source,
        extract(
            DAY FROM (l.created_at - lpc.last_click_date)
        ) AS days_to_close
    FROM leads AS l
    LEFT JOIN last_paid_click AS lpc
        ON l.visitor_id = lpc.visitor_id
    WHERE      
        l.created_at IS NOT NULL
        AND extract(
            DAY FROM (l.created_at - lpc.last_click_date)
        ) >= 0
)

SELECT
    ll.last_click_source,
    percentile_cont(0.9) WITHIN GROUP (
        ORDER BY ll.days_to_close
    ) AS p90_days_to_close
FROM lead_lags AS ll
GROUP BY ll.last_click_source;
