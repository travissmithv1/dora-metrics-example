WITH time_series AS (
    SELECT
        generate_series(
            (Cast($__timeFrom() as Date))::date,
            (Cast($__timeTo() as Date)),
            '1 day'::interval
        )::date AS day
),
filtered_time_series AS (
    SELECT
        day
    FROM
        time_series
    WHERE
        day > (SELECT date_trunc('day', min(deployed_on)) FROM deployment_frequency)
),
deployment_data AS (
    SELECT
        date_trunc('week', filtered_time_series.day) AS week,
        MAX(CASE WHEN deployments.day IS NOT NULL THEN 1 ELSE 0 END) AS week_deployed,
        COUNT(DISTINCT deployments.day) AS days_deployed,
        SUM(MAX(CASE WHEN deployments.day IS NOT NULL THEN 1 ELSE 0 END)) OVER (PARTITION BY date_trunc('month', date_trunc('week', filtered_time_series.day))) AS months_deployed
    FROM
        filtered_time_series
    LEFT JOIN (
        SELECT
            date_trunc('day', deployed_on) AS day,
            deployment_id
        FROM
            deployment_frequency
        where project_id = '$Project_Id'
    ) deployments ON deployments.day = filtered_time_series.day
    GROUP BY
        date_trunc('week', filtered_time_series.day)
),
deployment_frequency_calculations AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_deployed) >= 5 AS on_demand,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_deployed) >= 3 AS daily,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY week_deployed) >= 1 AS weekly,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY months_deployed) >= 1 AS is_monthly
    FROM
        deployment_data
)
SELECT
    CASE
        WHEN on_demand THEN 'On-Demand'
        WHEN daily THEN 'Daily'
        WHEN weekly THEN 'Weekly'
        WHEN is_monthly THEN 'Monthly'
        ELSE 'Yearly'
    END AS deployment_frequency
FROM
    deployment_frequency_calculations
LIMIT 1;
