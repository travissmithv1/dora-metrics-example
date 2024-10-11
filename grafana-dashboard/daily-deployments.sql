SELECT
DATE_TRUNC('day', deployed_on) AS day,
COUNT(DISTINCT deployment_id) AS deployments
FROM
deployment_frequency
WHERE project_id = '$Project_Id' and deployed_on >= Cast($__timeFrom() as Date) and deployed_on <= Cast($__timeTo() as Date)
GROUP BY day;
