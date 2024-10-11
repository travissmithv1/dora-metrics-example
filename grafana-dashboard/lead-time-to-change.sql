SELECT
  CASE
    WHEN y.median_time_to_change < 24 * 60 then 'Less than One Day'
    WHEN y.median_time_to_change < 168 * 60 then 'Less than One Week'
    WHEN y.median_time_to_change < 672 * 60 then 'Less than One Month'
    ELSE 'Greater than One Month'
    END as lead_time_to_change
FROM
      (select
           case when x.median_time_to_change is null then 0
               else x.median_time_to_change
               end as median_time_to_change
       from (select AVG(EXTRACT(EPOCH FROM (deployed_on - committed_on)) / 60) as median_time_to_change
    from lead_time_for_changes
    where project_id = '$Project_Id'
      and deployed_on >= Cast($__timeFrom() as Date) and deployed_on <= Cast($__timeTo() as Date)) as x) as y;
