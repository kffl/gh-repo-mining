# Public GitHub repository mining resources

## Filtering repositories with Google BigQuery

As GitHub contains over 28M public repositories (out of which over 3M have an open-source license), you may want to prefilter the interesting ones prior to downloading their contents for further examination (i.e. static code analysis).

[GitHub dataset on BigQuery](https://console.cloud.google.com/bigquery?p=bigquery-public-data&d=github_repos&t=commits&page=table) can be used in order to filter repositories. BigQuery is a serverless data warehouse with SQL support. You can query up to 1TB/mo for free. After exceeding that limit, it costs 5\$/TB.

Example query:

```SQL
SELECT
  contents.sample_repo_name,
  repo.watch_count
FROM
  `bigquery-public-data.github_repos.sample_contents` as contents
JOIN `bigquery-public-data.github_repos.sample_repos` as repo
  ON contents.sample_repo_name = repo.repo_name
WHERE
  REGEXP_CONTAINS(contents.content, '"express"')
  AND contents.sample_path LIKE 'package.json'
  AND repo.watch_count > 2
ORDER BY repo.watch_count DESC;
```

Selects all repositories with 3 or more stars that declare express dependency (have `"express"` listed in their `package.json` in the repo root directory) and sorts them by the number of stars.

The query above would return the following results:

```
sample_repo_name            watch_count
expressjs/express           2979
yelouafi/redux-saga         2423
bvaughn/react-virtualized   1888
howdyai/botkit              1578
react-toolbox/react-toolbox 882
jessepollak/commandl        873
...
```

Caveats and recommendations:

1. Do not use `SELECT *` to inspect rows of a given table, as even with `LIMIT` clause provided, all rows will get scanned and you will likely exceed your quota.
2. For query testing purposes, use smaller `_sample` datasets in order to save quota.
3. Always remember to check the estimated quota usage (bottom right corner of the editor -> `This query will process X GB when run.`, updates upon successful query parsing) before running the query.
4. Dataset description in resources browser appears to be outdated and does not match the description provided in the [GCP Marketplace](https://console.cloud.google.com/marketplace/product/github/github-repos?filter=solution-type:dataset&q=github&id=46ee22ab-2ca4-4750-81a7-3ee0f0150dcb)
5. There are some discrepancies in data schemas between `_sample` and regular datasets. `sample_commits` appears to be an old snapshot (it's latest commits are form 2016).
6. The dataset is updated weekly (check latest.sql).

Additional resources:

1. [Expressions, functions and operators in Standard SQL](https://cloud.google.com/bigquery/docs/reference/standard-sql/functions-and-operators) - Documentation of the SQL dialect that is being used in BigQuery
2. [All the open source code in GitHub now shared within BigQuery: Analyze all the code!](https://medium.com/google-cloud/github-on-bigquery-analyze-all-the-code-b3576fd2b150) - Numerous examples of queries. Bare in mind that some of the ones listed there were written in Legacy SQL, not Standard SQL.

## Retrieving repository details with GitHub API

GitHub exposes it's own api that allows users to integrate it with custom apps as well as browse public repos and retrieve their contents and metadata.

Example requests:

```
GET https://api.github.com/repos/expressjs/express/git/trees/master?recursive=true
// returns a tree (up to 1000 nodes) representing files in a repo

GET https://api.github.com/search/repositories?q=api+language:javascript&sort=stars&order=desc
// public repo search - rich metadata and flexible query building
```

```
GET https://raw.githubusercontent.com/kffl/gh-repo-mining/main/README.md
GET https://raw.githubusercontent.com/{userName}/{repoName}/{branchName}/{fileName}
```

### GitHub API clients - Octokit

For most programming languages, there is no need to manually implement API calls. [Octokit](https://github.com/octokit) is a collection of official GitHub API clients for most popular programming languages.

Caveats:

1. Requests to GitHub API are [rate limited](https://docs.github.com/en/free-pro-team@latest/rest/overview/resources-in-the-rest-api#rate-limiting). The default rate for unauthenticated users of 60 req/h (per IP) can be increased to 5000 req/h for authenticated users (either via OAuth or Basic Auth). Separate (more restrictive) limits apply to search queries. Request authentication is made easy with Octokit clients.
2. You can use `raw.githubusercontent.com` instead of `api.github.com` to download raw files (no need to convert them from in-JSON base64).

Resources:

1. [API Docs](https://docs.github.com/en/free-pro-team@latest/rest)
2. [Integration Guide](https://docs.github.com/en/free-pro-team@latest/developers/apps/using-the-github-api-in-your-app)
