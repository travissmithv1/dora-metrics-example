select x.deployed_on_date, (sum(x.lead_time) / count(*)) as average_number_of_days_to_change from (
SELECT Cast(to_char(committed_on, 'MM-DD-YYYY') as Date) as deployed_on_date, extract(epoch from deployed_on - committed_on) / 86400 as lead_time
from lead_time_for_changes where project_id = '$Project_Id' and committed_on >= Cast($__timeFrom() as Date) and committed_on <= Cast($__timeTo() as Date)
) as x
group by x.deployed_on_date
