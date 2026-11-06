---
name: under-construction
description: Pick up the Slack messages the user has marked with the :under-construction: reaction (🚧), list them, let the user choose one, and work out what to build — from the recent git log and the thread when that is enough, by a short grilling when it is not. Use when the user types /under-construction, asks "what's under construction", "what have I marked", "pick up my 🚧 items", or wants to work through flagged Slack requests.
argument-hint: "[channel name or keyword to narrow the list]"
---

# /under-construction: work through the user's 🚧 items in Slack

The user marks a Slack message they intend to build with the custom reaction
`:under-construction:` (shows as 🚧; the stock `:construction:` is a different
emoji and is **not** the marker). The marker is the user's own reaction: someone
else's 🚧 on a message does not count.

Shipped is the user's own `:ship-it-parrot:` on the same message, and the parrot
replaces 🚧. The Slack connector can add a reaction but not remove one, so the
search below treats a message with the user's parrot as done whether or not the
🚧 is still there.

## 1. Find the items

Load the Slack tools in one ToolSearch call:
`select:mcp__claude_ai_Slack__slack_search_public_and_private,mcp__claude_ai_Slack__slack_read_thread,mcp__claude_ai_Slack__slack_read_file,mcp__claude_ai_Slack__slack_add_reaction,mcp__claude_ai_Slack__slack_get_reactions,mcp__claude_ai_Slack__slack_send_message,mcp__claude_ai_Slack__slack_get_file_upload_url,mcp__claude_ai_Slack__slack_complete_file_upload`

Run these two searches in parallel with `slack_search_public_and_private`,
`sort: "timestamp"`, `include_context: false`, `natural_language_query: ""`:

- `filters: "hasmy::under-construction:"` (`response_format: "detailed"`, so you get channel ids and message ts)
- `filters: "hasmy::under-construction: hasmy::ship-it-parrot:"` (`response_format: "concise"`)

Open items are the first set minus the second. Page with `cursor` until the
first search is exhausted. If the user passed an argument, narrow the search with
`in:#<channel>` or add it as a keyword.

For each open item that has a thread, read the thread (`slack_read_thread`): the
ask often changes in the replies, and a reply may already say it was fixed. If a
reply from the user says it is done, show it as probably done rather than open.

## 2. List them and ask which one

Show a numbered list, oldest first, one item per line:

`N. #channel · Author · date — one-sentence summary of the ask, in English · [small | needs talk] · (N replies)`

- The summary is what should change, not a restatement of the message.
- `small` means you can already name the change and how to tell it works (see step 3).
  `needs talk` means you cannot. This is a guess from the message alone; say so
  if you are unsure.
- Add the permalink after the line.

Then ask which one to start with. With four or fewer items use AskUserQuestion,
recommending the one that looks smallest and clearest. With more, end the turn
with the list and let the user answer with a number. Do not start on anything
until the user picks.

## 3. Understand the chosen item

Gather context before asking anything:

1. The message, its thread, and any attached screenshots (`slack_read_file`). A
   screenshot usually shows exactly which screen and element is meant.
2. The user's recent work in the current repo:
   `git log --author="$(git config user.name)" --since="3 weeks ago" --format="%h %ad %s" --date=short`,
   plus `git branch --sort=-committerdate | head` and `git worktree list`. Look for
   commits and branches touching the same feature, screen or noun as the message.
3. The code itself: find the screen, tool or component the message names. Follow
   the repo's own routing (a `CLAUDE.md` "where a request goes" table, a
   `CONTEXT.md` glossary) before searching blind.

Then decide:

- **Clear enough** when you can write, without guessing:
  *what changes* (which file/component/behaviour), *how to tell it works*, and
  *what stays the same*. State those three in a few lines, say which commits or
  branches you leaned on, and ask the user to confirm or correct before
  changing code. One confirmation, not a questionnaire.
- **Not clear enough**: grill lightly.
  - One question at a time, each with your recommended answer and the reason.
  - Answer it yourself from the code or the git log whenever you can; only ask
    what only the user (or the person who wrote the message) knows: intent,
    scope, priority, which of two plausible meanings.
  - Stop as soon as the three things above are pinned down. Usually two or three
    questions; more than five means the item is bigger than a fix, so say so and
    suggest an issue or a plan instead of building.
  - If the user does not know either, offer to draft a reply in the thread asking
    the author, and show the draft before sending.

## 4. Build it

Work the item like any other change in the repo, following its own rules for
branches, tests, commits and deploys. Do not commit or push unless the user asks.

## 5. Close it out

Only once the change is live: merged and deployed, not just committed or in a
PR. A parrot on a message tells its author they can use the fix now. Then
propose both of these together in one confirmation, since each is visible to the
whole channel, and do what the user says yes to:

- Swap 🚧 for the parrot. Add `ship-it-parrot` with `slack_add_reaction`, which
  takes the item off the list. Then take the user's 🚧 off: with the Chrome
  extension connected, open the message's permalink in Slack on the web and
  click the user's own `:under-construction:` reaction pill, which toggles it
  off, and confirm with `slack_get_reactions` that the user is no longer on it.
  Without the browser, tell the user the 🚧 is theirs to tap off.
- A short thread reply saying what changed and where to see it. It goes out as
  the user, so write it in their voice: read their own recent messages in the
  channel and match the language, tone and length, not a formal style guide.
  - **Attach a screenshot when the change is something you can see**: a new
    button, a dialog, a changed layout. Skip it for a fix that looks the same
    as before, such as a calculation, a crash or a data repair.
  - Take it on localhost: start the app's dev server on the next free port,
    open the screen the message is about, and set up the state that shows the
    change (the field open, the dialog up). Capture only that part with the
    Chrome `zoom` action and `save_to_disk: true`.
  - **Save nothing while you set it up**: a dev server may write to production
    data. Show the dialog, then Cancel or Esc. Stop the dev server afterwards.
  - Upload with `slack_get_file_upload_url` and `slack_complete_file_upload`
    into the same thread.
  - The user may be on their phone and unable to check the image. Describe in
    one line what it shows when asking for the go-ahead.

Then show the remaining open items and ask whether to take the next one.
