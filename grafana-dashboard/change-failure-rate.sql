SELECT
    CASE
        WHEN change_fail_rate <= 0.15 THEN '0 - 15%'
        WHEN change_fail_rate < 0.46 THEN '16 - 45%'
        WHEN change_fail_rate < 0.61 THEN '46 - 60%'
        ELSE '61 - 100%'
    END AS change_failure_rate
FROM (
    SELECT
       SUM(CASE WHEN had_issues = 1 THEN had_issues ELSE 0 END) * 1.0 / COUNT(DISTINCT deployment_id) AS change_fail_rate
    FROM
        change_failure_rate
    WHERE project_id = '$Project_Id' and
        deployed_on >= Cast($__timeFrom() as Date) and deployed_on <= Cast($__timeTo() as Date)
) AS change_fail_rate_calculation
LIMIT 1;
