SELECT
    CASE
        WHEN med_time_to_resolve < 1 THEN 'Less than One Hour'
        WHEN med_time_to_resolve < 24 THEN 'Less than One Day'
        WHEN med_time_to_resolve < 168 THEN 'Less than One Week'
        WHEN med_time_to_resolve < 672 THEN 'Less than One Month'
        ELSE 'Greater than One Month'
    END AS med_time_to_resolve
FROM (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (issue_resolved_on - issue_occurred_on)) / 3600) AS med_time_to_resolve
    FROM
        time_to_restore_services
    WHERE project_id = '$Project_Id' and issue_occurred_on >= Cast($__timeFrom() as Date) and issue_occurred_on <= Cast($__timeTo() as Date)
) AS median_calculation
LIMIT 1;
