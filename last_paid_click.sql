WITH paid_sessions AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign
    FROM sessions s
    WHERE LOWER(s.medium) IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),
ranked_sessions AS (
    SELECT
        l.visitor_id,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.learning_format,
        l.status_id,
        ps.visit_date,
        ps.utm_source,
        ps.utm_medium,
        ps.utm_campaign,
        ROW_NUMBER() OVER (
            PARTITION BY l.visitor_id, l.lead_id
            ORDER BY ps.visit_date DESC
        ) AS rn
    FROM leads l
    LEFT JOIN paid_sessions ps
        ON l.visitor_id = ps.visitor_id
        AND ps.visit_date <= l.created_at
),
last_paid_clicks AS (
    SELECT *
    FROM ranked_sessions
    WHERE rn = 1
),
all_sessions_with_leads AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        COALESCE(lpc.utm_source, NULL) AS utm_source,
        COALESCE(lpc.utm_medium, NULL) AS utm_medium,
        COALESCE(lpc.utm_campaign, NULL) AS utm_campaign,
        lpc.lead_id,
        lpc.created_at,
        lpc.amount,
        lpc.closing_reason,
        lpc.status_id
    FROM sessions s
    LEFT JOIN last_paid_clicks lpc
        ON s.visitor_id = lpc.visitor_id
        AND s.visit_date = lpc.visit_date
)
SELECT *
FROM all_sessions_with_leads
ORDER BY
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC NULLS LAST,
    utm_medium ASC NULLS LAST,
    utm_campaign ASC NULLS LAST
LIMIT 10;
