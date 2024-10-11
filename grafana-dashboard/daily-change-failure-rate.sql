select x.deployed_on_date, ((cast(sum(x.had_issues) as decimal) / cast(count(x.deployed_on_date) as decimal)) * 100) as failure_percentage from (
select Cast(to_char(deployed_on, 'MM-DD-YYYY') as Date) as deployed_on_date, deployed_on, had_issues
from change_failure_rate
WHERE project_id = '$Project_Id' and deployed_on >= Cast($__timeFrom() as Date) and deployed_on <= Cast($__timeTo() as Date)
) x
group by x.deployed_on_date
