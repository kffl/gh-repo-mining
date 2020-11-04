SELECT
  count(*) as count,
  FORMAT_DATE("%F", DATE(TIMESTAMP_SECONDS(commits.committer.time_sec))) as day
FROM
  `bigquery-public-data.github_repos.commits` as commits
group by day
having count > 1000 
order by day desc;