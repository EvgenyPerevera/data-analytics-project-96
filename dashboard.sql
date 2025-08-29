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
