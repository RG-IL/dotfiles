# Composio Tool Reference

Single source of truth. **Read this entirely before any composio call.**
No searching. No listing. No guessing. Go straight to the known slug.

Replaces `mcp-tools.md` and the old composio section in `AGENTS.md`.

---

## 1. GOLDEN RULES

1. **Read this file first** — param names, types, quirks are here. No searching/listing tools.
2. **No guessing param names** — e.g. `HACKERNEWS_GET_ITEM_WITH_ID` expects `item_id` (string), not `id` (number). `HACKERNEWS_SEARCH_POSTS` expects `tags` as an array `["story"]`, not a string.
3. **Parallelize independent calls** — `GITHUB_GET_THE_AUTHENTICATED_USER` + `GITHUB_GET_REPOSITORY_CONTENT` can run in parallel.
4. **Owner unknown?** Call `GITHUB_GET_THE_AUTHENTICATED_USER` first (no params).
5. **`data` is always a JSON object** — pass as `{}` for no-param tools.
6. **After successful use**, update this file with any new quirks discovered.

## 2. QUICK REFERENCE — COMMON TASKS

| Task | Tool Slug | Key Params |
|------|-----------|------------|
| "who am I on GitHub" | `GITHUB_GET_THE_AUTHENTICATED_USER` | none |
| "list my repos" | `GITHUB_LIST_REPOSITORIES_FOR_THE_AUTHENTICATED_USER` | `sort`, `type`, `per_page` |
| "list files in repo X" | `GITHUB_GET_REPOSITORY_CONTENT` | `owner`, `repo`, `path:""` |
| "read file in repo X" | `GITHUB_GET_REPOSITORY_CONTENT` | `owner`, `repo`, `path:"file.ext"` |
| "get repo info" | `GITHUB_GET_A_REPOSITORY` | `owner`, `repo` |
| "list PRs in repo" | `GITHUB_LIST_PULL_REQUESTS` | `owner`, `repo` |
| "search HN posts" | `HACKERNEWS_SEARCH_POSTS` | `query`, `tags:["story"]` |
| "top HN stories" | `HACKERNEWS_GET_TOP_STORIES` | none |
| "weather forecast" | `OPENWEATHER_API_GET5_DAY_FORECAST` | one of `q`, `id`, `zip`, or `lat`+`lon` |
| "current weather" | `OPENWEATHER_API_GET_CURRENT_WEATHER` | one of `q`, `id`, `zip`, or `lat`+`lon` |
| "geocode city name" | `OPENWEATHER_API_GET_GEOCODING_DIRECT` | `q:"City,Country"` |
| "text to PDF" | `TEXT_TO_PDF_CONVERT_TEXT_TO_PDF` | `file_type`, `text` |

## 3. PER-TOOLKIT REFERENCE

### github

| Slug | Description |
|------|-------------|
| `GITHUB_ABORT_REPOSITORY_MIGRATION` | Abort a queued or in-progress repository migration |
| `GITHUB_ACCEPT_REPOSITORY_INVITATION` | Accept a PENDING repo invitation |
| `GITHUB_ADD_APP_ACCESS_RESTRICTIONS` | Add GitHub Apps to allowed-push list for a protected branch |
| `GITHUB_ADD_A_REPOSITORY_COLLABORATOR` | Add/update a collaborator. `owner`, `repo`, `username` (all string). `permission`: push\|pull\|admin\|maintain\|triage (org repos only) |
| `GITHUB_ADD_ASSIGNEES_TO_AN_ISSUE` | Add assignees to an issue |
| `GITHUB_ADD_EMAIL_ADDRESS_FOR_AUTHENTICATED_USER` | Add emails to your account |
| `GITHUB_ADD_FIELD_TO_USER_PROJECT` | Add custom field to a user-owned GitHub Projects V2 project |
| `GITHUB_ADD_ITEM_TO_USER_PROJECT` | Add issue/PR to a user-owned GitHub project |
| `GITHUB_ADD_LABELS_TO_AN_ISSUE` | Add labels to an issue; creates them if missing |
| `GITHUB_ADD_ORG_RUNNER_LABELS` | Add custom labels to an org self-hosted runner |
| `GITHUB_ADD_OR_UPDATE_TEAM_MEMBERSHIP_FOR_USER` | Add/update team membership |
| `GITHUB_ADD_OR_UPDATE_TEAM_PROJECT_PERMISSIONS` | Set team permission on a classic project (not V2) |
| `GITHUB_ADD_OR_UPDATE_TEAM_REPOSITORY_PERMISSIONS` | Set team permission level for a repo |
| `GITHUB_ADD_PROJECT_COLLABORATOR` | Add a collaborator to an org classic project |
| `GITHUB_ADD_REPOSITORY_TO_APP_INSTALLATION` | Add a repo to a GitHub App installation |
| `GITHUB_ADD_REPO_TO_ORG_SECRET_WITH_SELECTED_ACCESS` | Add repo to an org secret with selected access |
| `GITHUB_ADD_REPO_TO_ORG_SECRET_WITH_SELECTED_VISIBILITY` | Grant repo access to an org Dependabot secret |
| `GITHUB_ADD_RUNNER_LABELS` | Add custom labels to a self-hosted runner |
| `GITHUB_ADD_SELECTED_REPOSITORY_TO_ORGANIZATION_SECRET` | Add repo to org secret's selected access list |
| `GITHUB_ADD_SELECTED_REPOSITORY_TO_ORGANIZATION_VARIABLE` | Grant repo access to an org Actions variable |
| `GITHUB_ADD_SELECTED_REPOSITORY_TO_USER_SECRET` | Grant repo access to your Codespaces secret |
| `GITHUB_ADD_SOCIAL_ACCOUNTS_FOR_AUTHENTICATED_USER` | Add social links to your public GitHub profile |
| `GITHUB_ADD_STATUS_CHECK_CONTEXTS` | Add status check contexts to a protected branch |
| `GITHUB_ADD_SUB_ISSUE` | Add a sub-issue to a parent issue (GraphQL) |
| `GITHUB_ADD_TEAM_ACCESS_RESTRICTIONS` | Add teams to push-access list for a protected branch (org repos only) |
| `GITHUB_ADD_USER_ACCESS_RESTRICTIONS` | Add users to push-access list for a protected branch (org repos only) |
| `GITHUB_ADD_USERS_TO_CODESPACES_ACCESS_FOR_ORGANIZATION` | Add org members to Codespaces billing access list |
| `GITHUB_API_ROOT` | Get top-level GitHub REST API resource URLs |
| `GITHUB_APPROVE_WORKFLOW_RUN_FOR_FORK_PULL_REQUEST` | Approve a workflow run from a fork PR |
| `GITHUB_ASSIGN_ORGANIZATION_ROLE_TO_TEAM` | Assign an org role to a team |
| `GITHUB_CHECK_IF_USER_IS_REPOSITORY_COLLABORATOR` | Check if user is a collaborator. `owner`, `repo`, `username` (all string) |
| `GITHUB_FIND_PULL_REQUESTS` | Search PRs across repos. `repo`, `label`, `sort`, `order`, `page`. *Pitfall:* results in `data.items` |
| `GITHUB_GET_A_REPOSITORY` | Get repo metadata. `owner`, `repo`. Response includes `default_branch`, `description` |
| `GITHUB_GET_REPOSITORY_CONTENT` | **Most used.** List files or read a file. **Required:** `owner`, `repo`, `path`. `ref` for branch/tag. Case-sensitive paths. `""` for root. Branch in `ref`, NOT `path`. Response: dir→array, file→object w/ Base64 |
| `GITHUB_GET_THE_AUTHENTICATED_USER` | **Call first when owner unknown.** No params. Response: `login`, `id`, `name`, `public_repos` |
| `GITHUB_LIST_PULL_REQUESTS` | List PRs in a specific repo. **Required:** `owner`, `repo`. `base`, `head`, `sort`, `page` |
| `GITHUB_LIST_REPOSITORIES_FOR_THE_AUTHENTICATED_USER` | List your repos. `sort`, `type`, `per_page`, `since`, `before`, `page`, `direction`. Response: `data.repositories` |
| `GITHUB_LIST_REPOSITORY_INVITATIONS` | List pending repo invitations. `owner`, `repo` |
| `GITHUB_REQUEST_REVIEWERS_FOR_A_PULL_REQUEST` | Request PR reviewers. `owner`, `repo`, `pull_number` (int). `reviewers` (string[]), `team_reviewers` (string[]) |

### virustotal

| Slug | Description |
|------|-------------|
| `VIRUSTOTAL_ADD_COMMENT` | Add a comment to a resource (file, URL, domain, IP) |
| `VIRUSTOTAL_ADD_VOTE` | Add a vote (harmless/malicious) to a resource |
| `VIRUSTOTAL_GET_ANALYSIS` | Get analysis report of a file or URL submission |
| `VIRUSTOTAL_GET_COMMENTS` | Get latest comments on a resource |
| `VIRUSTOTAL_GET_DOMAIN_RELATIONSHIPS` | Get relationship objects for a domain |
| `VIRUSTOTAL_GET_DOMAIN_REPORT` | Get domain analysis report |
| `VIRUSTOTAL_GET_FILE_REPORT` | Get file analysis report |
| `VIRUSTOTAL_GET_IP_ADDRESS_RELATIONSHIPS` | Get objects related to an IP by relationship type |
| `VIRUSTOTAL_GET_IP_ADDRESS_REPORT` | Get IP address analysis report |
| `VIRUSTOTAL_GET_METADATA` | Get VirusTotal metadata |
| `VIRUSTOTAL_GET_URL_REPORT` | Get URL analysis report |
| `VIRUSTOTAL_GET_VOTES` | Get votes on files, URLs, domains, or IPs |
| `VIRUSTOTAL_RESCAN_FILE` | Re-analyze a previously submitted file |
| `VIRUSTOTAL_SCAN_URL` | Submit a URL for scanning |
| `VIRUSTOTAL_SEARCH` | Search the VirusTotal database |
| `VIRUSTOTAL_UPLOAD_FILE` | Upload a file for scanning |

### openweather_api

**Location constraint:** Exactly ONE of `q` (city name), `id` (city ID), `zip` (zip code), or `lat`+`lon` pair — never multiple at once.

| Slug | Description |
|------|-------------|
| `OPENWEATHER_API_DELETE_WEATHER_STATION` | Delete a registered weather station |
| `OPENWEATHER_API_GET5_DAY_FORECAST` | 5-day forecast every 3 hours. Location + `units` (standard\|metric\|imperial), `lang` (ISO 639-1), `mode` (json\|xml\|html). `city.timezone` converts UTC to local |
| `OPENWEATHER_API_GET_AIR_POLLUTION_CURRENT` | Current air pollution. Needs `lat`+`lon` |
| `OPENWEATHER_API_GET_AIR_POLLUTION_FORECAST` | Forecasted air pollution. Needs `lat`+`lon` |
| `OPENWEATHER_API_GET_AIR_POLLUTION_HISTORY` | Historical air pollution. Needs `lat`+`lon` |
| `OPENWEATHER_API_GET_CIRCLE_CITY_WEATHER` | Search weather around a geographic point |
| `OPENWEATHER_API_GET_CURRENT_WEATHER` | Current weather. Same location params as forecast |
| `OPENWEATHER_API_GET_GEOCODING_BY_ZIP` | Zip/post code to coordinates |
| `OPENWEATHER_API_GET_GEOCODING_DIRECT` | City name to coordinates. **Call before weather lookups.** `q` (string, e.g. `London,UK`), `limit` (int, 1–5) |
| `OPENWEATHER_API_GET_GEOCODING_REVERSE` | Coordinates to location name |
| `OPENWEATHER_API_GET_STATION_MEASUREMENTS` | Aggregated measurements from a weather station |
| `OPENWEATHER_API_GET_UV_INDEX` | Current UV index. Needs `lat`+`lon` |
| `OPENWEATHER_API_GET_UV_INDEX_FORECAST` | UV forecast. Needs `lat`+`lon` |
| `OPENWEATHER_API_GET_UV_INDEX_HISTORY` | Historical UV. Needs `lat`+`lon` |
| `OPENWEATHER_API_GET_WEATHER_MAP_TILE` | Fetch Weather Maps 2.0 tiles |
| `OPENWEATHER_API_GET_WEATHER_STATION` | Get a specific weather station by ID |
| `OPENWEATHER_API_GET_WEATHER_STATIONS` | List all your weather stations |
| `OPENWEATHER_API_GET_WEATHER_TRIGGERS` | Get weather triggers for specific conditions |
| `OPENWEATHER_API_POST_ADD_WEATHER_STATION` | Register a new weather station |
| `OPENWEATHER_API_POST_SUBMIT_STATION_MEASUREMENTS` | Submit measurements from a registered station |
| `OPENWEATHER_API_UPDATE_WEATHER_STATION` | Update weather station details |

### weathermap

| Slug | Description |
|------|-------------|
| `WEATHERMAP_GEOCODE_LOCATION` | Resolve place name to lat/lon via OpenWeather Geocoding API |
| `WEATHERMAP_WEATHER` | Query the OpenWeatherMap API |

### text_to_pdf

| Slug | Description |
|------|-------------|
| `TEXT_TO_PDF_CONVERT_TEXT_TO_PDF` | Convert plain text or Markdown to PDF. **Required:** `file_type` (txt\|markdown), `text` (string). Content must be complete inline |
| `TEXT_TO_PDF_DELETE_ASYNC_JOB` | Delete an async conversion job |
| `TEXT_TO_PDF_DELETE_FILE` | Delete a file from ConvertAPI server |
| `TEXT_TO_PDF_DOWNLOAD_FILE` | Download a file using its File ID |
| `TEXT_TO_PDF_START_ASYNC_CONVERSION` | Start an async file conversion job |
| `TEXT_TO_PDF_UPLOAD_FILE` | Upload a file for subsequent conversions |

### pdf4me

| Slug | Description |
|------|-------------|
| `PDF4ME_CONVERT_TO_PDF` | Convert documents/images to PDF |
| `PDF4ME_EXTRACT_TEXT` | Extract embedded text from text-based PDFs |
| `PDF4ME_FILL_PDF_FORM` | Fill PDF form fields programmatically via JSON/XML |
| `PDF4ME_READ_BARCODES_FROM_IMAGE` | Read barcode/QR data from image files (JPG/PNG) |

### seatgeek

| Slug | Description |
|------|-------------|
| `SEAT_GEEK_SEARCH_PERFORMERS` | Search performers (artists, teams, etc.). `q` (string), `id` (string, comma-separated), `slug` (string), `per_page` (int, 1–100, default 10), `taxonomies_id`, `taxonomies_name` |

### hackernews

| Slug | Description |
|------|-------------|
| `HACKERNEWS_GET_ITEM` | Get single item by numeric ID. `id` (integer) — **number, not string** |
| `HACKERNEWS_GET_ITEM_WITH_ID` | Get item with nested comments. `item_id` (string) — **string, not number** (differs from GET_ITEM!). `max_depth` (int, default 2), `max_children` (int, default 10), `truncate_text` (bool, default true) |
| `HACKERNEWS_GET_LATEST_POSTS` | Get latest posts. No params |
| `HACKERNEWS_GET_TOP_STORIES` | Get current top stories. No params |
| `HACKERNEWS_SEARCH_POSTS` | Full-text search. **Required:** `query` (string). `tags` (string[]) — **must be array**, not string. `page` (int, 0-indexed), `size` (int, default 5) |

### composio (built-in MCP tools)

| Slug | Description |
|------|-------------|
| `composio_search` | Find tool slugs by use case. `query` (string), `limit` (int). Use only for unfamiliar tasks |
| `composio_execute` | Execute a tool by slug. `slug` (string), `data` (object — JSON params) |
| `composio_run` | Run inline JS with pre-injected `execute()` and `search()`. `code` (string) |
| `composio_link` | Connect a toolkit account. `toolkit` (string) |
| `composio_tools_list` | List tools in a toolkit. `toolkit` (string) |

## 4. FAILURE DEBUGGING

1. **Check this file** — wrong param type is the #1 cause (string vs number, array vs string)
2. **Read schema** from `~/.composio/tool_definitions/<SLUG>.json`
3. **Use `composio tools info <SLUG>`** if available via CLI
4. **Common mistake: branch names in `path`** — they belong in `ref`, never in `path`
