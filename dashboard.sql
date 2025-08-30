--CPU = total_cost / visitors_count
WITH u AS (
    SELECT
        LOWER(source) AS channel,
        COUNT(DISTINCT visitor_id) AS visitors_count
    FROM sessions
    WHERE LOWER(source) IN ('vk', 'yandex')
    GROUP BY LOWER(source)
)

SELECT
    c.channel,
    ROUND(c.total_cost::numeric / NULLIF(u.visitors_count, 0), 2) AS cpu
FROM (
    SELECT
        'vk' AS channel,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    UNION ALL
    SELECT
        'yandex' AS channel,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
) AS c
INNER JOIN u
    ON c.channel = u.channel;

--CPL = total_cost / leads_count
SELECT
    c.channel,
    ROUND(c.total_cost::numeric / NULLIF(l.leads_count, 0), 2) AS cpl
FROM (
    SELECT
        'vk' AS channel,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    UNION ALL
    SELECT
        'yandex' AS channel,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
) AS c
INNER JOIN (
    SELECT
        LOWER(s.source) AS channel,
        COUNT(DISTINCT l.lead_id) AS leads_count
    FROM leads AS l
    INNER JOIN sessions AS s ON l.visitor_id = s.visitor_id
    WHERE LOWER(s.source) IN ('vk', 'yandex')
    GROUP BY LOWER(s.source)
) AS l
    ON c.channel = l.channel;

--CPPU = total_cost / purchases_count
WITH p AS (
    SELECT
        LOWER(s.source) AS channel,
        COUNT(DISTINCT l.lead_id) AS purchases_count
    FROM leads AS l
    INNER JOIN sessions AS s ON l.visitor_id = s.visitor_id
    WHERE
        LOWER(s.source) IN ('vk', 'yandex')
        AND (l.closing_reason = 'Успешно реализовано' OR l.status_id = 142)
    GROUP BY
        LOWER(s.source)
)

SELECT
    c.channel,
    ROUND(c.total_cost::numeric / NULLIF(p.purchases_count, 0), 2) AS cppu
FROM (
    SELECT
        'vk' AS channel,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    UNION ALL
    SELECT
        'yandex' AS channel,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
) AS c
INNER JOIN p
    ON c.channel = p.channel;

--ROI = (revenue - total_cost) / total_cost
WITH r AS (
    SELECT
        LOWER(s.source) AS channel,
        SUM(l.amount) AS revenue
    FROM leads AS l
    INNER JOIN sessions AS s
        ON l.visitor_id = s.visitor_id
    WHERE
        LOWER(s.source) IN ('vk', 'yandex')
        AND (l.closing_reason = 'Успешно реализовано' OR l.status_id = 142)
    GROUP BY LOWER(s.source)
)

SELECT
    c.channel,
    ROUND((r.revenue - c.total_cost)::numeric / NULLIF(c.total_cost, 0), 4)
        AS roi
FROM (
    SELECT
        'vk' AS channel,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    UNION ALL
    SELECT
        'yandex' AS channel,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
) AS c
INNER JOIN r
    ON c.channel = r.channel;
