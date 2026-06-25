# Agent Instructions

## Tool reference (memorized — never guess)

### Built-in tools
| Tool | Required params | Optional params | Notes |
|------|----------------|-----------------|-------|
| `bash` | `command` (string), `description` (string) | `timeout` (int, ms), `workdir` (string) | Use `workdir` instead of `cd`; chain with `&&` for sequential commands |
| `read` | `filePath` (string) | `offset` (int, 1-indexed), `limit` (int) | Returns lines prefixed `N: content`; auto-truncates at 2000 lines |
| `write` | `filePath` (string), `content` (string) | — | Overwrites existing file; must `read` first if file exists |
| `edit` | `filePath` (string), `oldString` (string), `newString` (string) | `replaceAll` (boolean) | Exact match of `oldString` — fails if 0 or 2+ matches (use `replaceAll` for duplicates) |
| `grep` | `pattern` (string, regex) | `path` (string), `include` (string, glob) | Content search with regex |
| `glob` | `pattern` (string, glob) | `path` (string) | File name pattern matching |
| `webfetch` | `url` (string) | `format` (text\|markdown\|html), `timeout` (int, s) | Fetches and returns content |
| `websearch` | `query` (string) | `numResults` (int), `livecrawl` (fallback\|preferred), `type` (auto\|fast\|deep), `contextMaxCharacters` (int) | Real-time web search |
| `question` | `questions` (array of `{question, header, options}`) | — | Ask user for input; `multiple: true` for multi-select |
| `todowrite` | `todos` (array of `{content, status, priority}`) | — | Track task progress |
| `task` | `description` (string), `prompt` (string), `subagent_type` (explore\|general) | `task_id` (string, resume), `command` (string) | Launch sub-agents |
| `skill` | `name` (string) | — | Load a skill's instructions |

### Context7 MCP
| Tool | Required params | Notes |
|------|----------------|-------|
| `context7_resolve-library-id` | `query` (string, the question), `libraryName` (string, official name) | Resolve "nextjs" → "/vercel/next.js"; call BEFORE `query-docs` |
| `context7_query-docs` | `libraryId` (string, e.g. `/vercel/next.js`), `query` (string, your question) | Max 3 calls per question |

### Composio MCP (wrapper)
| Tool | Required params | Notes |
|------|----------------|-------|
| `composio_execute` | `slug` (string), `data` (object) | Prefer this over built-in `composio_composio_execute` |
| `composio_search` | `query` (string) | `limit` (optional int) | Find tool slugs by use case |
| `composio_tools_list` | `toolkit` (string) | List tools in a toolkit |
| `composio_link` | `toolkit` (string) | Connect an account |
| `composio_run` | `code` (string JS) | Multi-step scripts with injected `execute()`/`search()` |

### Composio app tools

**THE ONLY FILE YOU NEED: `~/.config/opencode/learned-tools.md`**

Read it before every composio call. Every slug, param, type, and quirk is there.
No searching. No listing. Go straight to the known slug.

**After connecting a new toolkit**, tell me the toolkit slug and I'll:
1. Add it to `~/.config/opencode/scripts/refresh-tools.sh`
2. Run the script to discover new tools and manually merge additions into `learned-tools.md`
