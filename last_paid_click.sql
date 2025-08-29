SELECT
    t.visitor_id,
    t.visit_date,
    t.utm_source,
    t.utm_medium,
    t.utm_campaign,
    t.lead_id,
    t.created_at,
    t.amount,
    t.closing_reason,
    t.status_id
FROM (
    SELECT
        s.visitor_id,
        s.visit_date::timestamp AS visit_date,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        lower(s.source) AS utm_source,
        lower(s.medium) AS utm_medium,
        lower(s.campaign) AS utm_campaign,
        row_number() OVER (
            PARTITION BY l.lead_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM leads AS l
    INNER JOIN sessions AS s
        ON
            l.visitor_id = s.visitor_id
            AND l.created_at >= s.visit_date
            AND lower(s.medium) IN (
                'cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social'
            )
) AS t
WHERE t.rn = 1
ORDER BY
    t.amount DESC NULLS LAST,
    t.visit_date ASC,
    t.utm_source ASC,
    t.utm_medium ASC,
    t.utm_campaign ASC
LIMIT 10;
