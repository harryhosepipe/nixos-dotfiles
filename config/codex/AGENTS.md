# context-mode - routing rules

Context Mode MCP tools are available. Use them when a command, file, or web page may produce large output.

## Think In Code

For analyze, count, filter, compare, search, parse, or transform work, prefer Context Mode tools instead of loading raw data into the chat.

Use:

- `ctx_execute` for scripts and shell commands where only the result matters.
- `ctx_execute_file` for processing a large file without pasting the whole file into context.
- `ctx_batch_execute` for several commands plus follow-up searches in one pass.
- `ctx_fetch_and_index` plus `ctx_search` for web pages or docs.
- `ctx_index` for saving important text into the searchable context store.
- `ctx_search` to retrieve earlier indexed output or session memory.

## Avoid Raw Context Floods

Do not use raw shell, file reads, grep output, or web fetches when the expected output is large and the goal is analysis rather than editing.

Use direct reads only when the exact file content is needed for an edit or review.

## Utility Commands

When the user says:

- `ctx stats`: call the Context Mode stats tool.
- `ctx doctor`: call the Context Mode doctor tool and summarize the checklist.
- `ctx upgrade`: call the Context Mode upgrade tool and report the required steps.
- `ctx purge`: call the Context Mode purge tool only after warning that it permanently deletes indexed context.

## Session Continuity

After resume or compaction, search Context Mode memory before asking the user what was happening:

- Decisions: `ctx_search` for `decision`.
- Constraints: `ctx_search` for `constraint`.
- Rejected approaches: `ctx_search` for `rejected`.
- Summary: `ctx_search` for `summary`.

If search returns nothing useful, continue as a fresh session.
