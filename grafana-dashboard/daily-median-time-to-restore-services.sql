select x.issue_occurred_on_date, (sum(x.time_to_restore_services) / count(*)) as average_number_of_days_to_restore_services from (
SELECT Cast(to_char(issue_occurred_on, 'MM-DD-YYYY') as Date) as issue_occurred_on_date, extract(epoch from issue_resolved_on - issue_occurred_on) / 86400 as time_to_restore_services
from time_to_restore_services where project_id = '$Project_Id' and issue_occurred_on >= Cast($__timeFrom() as Date) and issue_occurred_on <= Cast($__timeTo() as Date)
) as x
group by x.issue_occurred_on_date
