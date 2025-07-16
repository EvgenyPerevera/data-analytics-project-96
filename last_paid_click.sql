INSERT INTO "WITH paid_sessions AS (
    SELECT
        visitor_id,
        visit_date,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign,
        content AS utm_content
    FROM sessions
    WHERE LOWER(medium) IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),
ranked_paid_sessions AS (
    SELECT
        l.visitor_id,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        ps.visit_date,
        ps.utm_source,
        ps.utm_medium,
        ps.utm_campaign
    FROM leads l
    LEFT JOIN paid_sessions ps
        ON l.visitor_id = ps.visitor_id
        AND ps.visit_date <= l.created_at
),
last_paid_clicks AS (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY visitor_id, lead_id ORDER BY visit_date DESC) AS rn
        FROM ranked_paid_sessions
    ) t
    WHERE rn = 1
),
vk_costs AS (
    SELECT
        campaign_date AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS cost
    FROM vk_ads
    GROUP BY 1, 2, 3, 4
),
ya_costs AS (
    SELECT
        campaign_date AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS cost
    FROM ya_ads
    GROUP BY 1, 2, 3, 4
),
ads_costs AS (
    SELECT * FROM vk_costs
    UNION ALL
    SELECT * FROM ya_costs
),
aggregated AS (
    SELECT
        ps.visit_date,
        ps.utm_source,
        ps.utm_medium,
        ps.utm_campaign,
        COUNT(DISTINCT ps.visitor_id) AS visitors_count,
        COUNT(DISTINCT lpc.lead_id) AS leads_count,
        COUNT(DISTINCT CASE
            WHEN lpc.closing_reason = 'Успешно реализовано' OR lpc.status_id = 142 THEN lpc.lead_id
        END) AS purchases_count,
        SUM(CASE
            WHEN lpc.closing_reason = 'Успешно реализовано' OR lpc.status_id = 142 THEN lpc.amount
        END) AS revenue
    FROM paid_sessions ps
    LEFT JOIN last_paid_clicks lpc
        ON ps.visitor_id = lpc.visitor_id
        AND ps.visit_date = lpc.visit_date
    GROUP BY 1, 2, 3, 4
)
SELECT
    a.visit_date,
    a.utm_source,
    a.utm_medium,
    a.utm_campaign,
    a.visitors_count,
    a.leads_count,
    a.purchases_count,
    a.revenue
FROM aggregated a
LEFT JOIN ads_costs c
    ON a.visit_date = c.visit_date
    AND a.utm_source = c.utm_source
    AND a.utm_medium = c.utm_medium
    AND a.utm_campaign = c.utm_campaign
ORDER BY
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC
LIMIT 15" (visit_date,utm_source,utm_medium,utm_campaign,visitors_count,leads_count,purchases_count,revenue) VALUES
	 ('2023-06-01 10:40:28','yandex','cpc','prof-frontend',1,1,1,237990),
	 ('2023-06-01 19:27:00','yandex','cpc','freemium',2,2,2,232766),
	 ('2023-06-01 14:39:00','yandex','cpc','base-frontend',1,1,1,201150),
	 ('2023-06-01 04:58:00','vk','cpc','freemium-frontend',1,1,1,189210),
	 ('2023-06-01 10:44:00','yandex','cpc','freemium',1,1,1,188991),
	 ('2023-06-01 14:57:00','yandex','cpc','prof-frontend',1,1,1,180306),
	 ('2023-06-01 03:41:00','vk','cpc','prof-java',1,1,1,178800),
	 ('2023-06-01 19:39:00','yandex','cpc','prof-frontend',1,1,1,167625),
	 ('2023-06-01 11:34:00','yandex','cpc','base-python',1,1,1,160920),
	 ('2023-06-20 15:15:04.7015','telegram','cpp','base-java',1,1,1,151192);
INSERT INTO "WITH paid_sessions AS (
    SELECT
        visitor_id,
        visit_date,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign,
        content AS utm_content
    FROM sessions
    WHERE LOWER(medium) IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),
ranked_paid_sessions AS (
    SELECT
        l.visitor_id,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        ps.visit_date,
        ps.utm_source,
        ps.utm_medium,
        ps.utm_campaign
    FROM leads l
    LEFT JOIN paid_sessions ps
        ON l.visitor_id = ps.visitor_id
        AND ps.visit_date <= l.created_at
),
last_paid_clicks AS (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY visitor_id, lead_id ORDER BY visit_date DESC) AS rn
        FROM ranked_paid_sessions
    ) t
    WHERE rn = 1
),
vk_costs AS (
    SELECT
        campaign_date AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS cost
    FROM vk_ads
    GROUP BY 1, 2, 3, 4
),
ya_costs AS (
    SELECT
        campaign_date AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS cost
    FROM ya_ads
    GROUP BY 1, 2, 3, 4
),
ads_costs AS (
    SELECT * FROM vk_costs
    UNION ALL
    SELECT * FROM ya_costs
),
aggregated AS (
    SELECT
        ps.visit_date,
        ps.utm_source,
        ps.utm_medium,
        ps.utm_campaign,
        COUNT(DISTINCT ps.visitor_id) AS visitors_count,
        COUNT(DISTINCT lpc.lead_id) AS leads_count,
        COUNT(DISTINCT CASE
            WHEN lpc.closing_reason = 'Успешно реализовано' OR lpc.status_id = 142 THEN lpc.lead_id
        END) AS purchases_count,
        SUM(CASE
            WHEN lpc.closing_reason = 'Успешно реализовано' OR lpc.status_id = 142 THEN lpc.amount
        END) AS revenue
    FROM paid_sessions ps
    LEFT JOIN last_paid_clicks lpc
        ON ps.visitor_id = lpc.visitor_id
        AND ps.visit_date = lpc.visit_date
    GROUP BY 1, 2, 3, 4
)
SELECT
    a.visit_date,
    a.utm_source,
    a.utm_medium,
    a.utm_campaign,
    a.visitors_count,
    a.leads_count,
    a.purchases_count,
    a.revenue
FROM aggregated a
LEFT JOIN ads_costs c
    ON a.visit_date = c.visit_date
    AND a.utm_source = c.utm_source
    AND a.utm_medium = c.utm_medium
    AND a.utm_campaign = c.utm_campaign
ORDER BY
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC
LIMIT 15" (visit_date,utm_source,utm_medium,utm_campaign,visitors_count,leads_count,purchases_count,revenue) VALUES
	 ('2023-06-01 16:43:00','yandex','cpc','dod-php',1,1,1,150255),
	 ('2023-06-01 15:46:00','yandex','cpc','prof-data-analytics',1,1,1,144244),
	 ('2023-06-01 08:33:02','yandex','cpc','prof-python',1,1,1,134100),
	 ('2023-06-01 10:54:00','yandex','cpc','freemium',1,1,1,134100),
	 ('2023-06-01 19:10:00','yandex','cpc','base-professions-retarget',1,1,1,134100);
