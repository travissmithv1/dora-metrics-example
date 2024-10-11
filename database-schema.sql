create table project
(
    id         uuid,
    name       varchar(200),
    created_on timestamp
);

create table deployment
(
    id              uuid,
    project_id      uuid,
    release_tag     varchar(200),
    deployed_on     timestamp,
    created_on      timestamp,
    repository_name varchar(500)
);

create table commit
(
    id            uuid,
    commit_id     bytea,
    committed_on  timestamp,
    deployment_id uuid,
    created_on    timestamp
);

create table issue
(
    id                       uuid,
    issue_id                 varchar(500),
    originated_deployment_id uuid,
    resolution_deployment_id uuid,
    created_on               timestamp
);

create view deployment_frequency(deployment_id, project_id, deployed_on) as
SELECT deployment.id AS deployment_id,
       deployment.project_id,
       deployment.deployed_on
FROM deployment;

create view lead_time_for_changes(commit_id, project_id, committed_on, deployed_on) as
SELECT c.id AS commit_id,
       d.project_id,
       c.committed_on,
       d.deployed_on
FROM commit c
         JOIN deployment d ON d.id = c.deployment_id;

create view change_failure_rate(deployment_id, project_id, deployed_on, had_issues) as
SELECT d.id AS deployment_id,
       d.project_id,
       d.deployed_on,
       1    AS had_issues
FROM deployment d
WHERE (EXISTS (SELECT s.id
               FROM issue s
               WHERE s.originated_deployment_id = d.id))
UNION ALL
SELECT d.id AS deployment_id,
       d.project_id,
       d.deployed_on,
       0    AS had_issues
FROM deployment d
WHERE NOT (EXISTS (SELECT s.id
                   FROM issue s
                   WHERE s.originated_deployment_id = d.id));

create view time_to_restore_services(issue_id, project_id, issue_occurred_on, issue_resolved_on) as
SELECT i.id           AS issue_id,
       od.project_id,
       od.deployed_on AS issue_occurred_on,
       rd.deployed_on AS issue_resolved_on
FROM issue i
         JOIN deployment od ON i.originated_deployment_id = od.id
         JOIN deployment rd ON i.resolution_deployment_id = rd.id;
