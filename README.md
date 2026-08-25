# For Teammate — How to Add Your Chatbot Work

This repo has one feature per folder. Follow the same pattern for the
chatbot so everything stays organized and the backend team can
understand it easily.

## Current Repo Structure

```
SIH-2026-Ai-Ml/
├── service_discovery/   (Nikhil - done)
├── worker_matching/     (Nikhil - done)
├── chatbot/              (you - add this)
└── README.md
```

## Steps to Add Your Work

1. **Create a new folder in the repo root** named exactly `chatbot`
   (lowercase, no spaces). Do NOT put it inside any other folder.

2. **Put all your chatbot files inside it** — your training data, your
   model/script, and your FastAPI file (if you're exposing it as an API
   like the other two features).

3. **Add a small `README.md` inside your `chatbot/` folder** explaining:
   - What it does (one or two lines)
   - How it works (what technique/library you used)
   - How to run it (exact commands, like `pip install ...` then `python3 ...`)
   - Which port it runs on

   You can copy the style from `service_discovery/` or `worker_matching/`
   if you check inside them — same pattern, just your content.

4. **Push it to the same repo** (same branch, `main`), so it shows up
   next to the other two folders — not as a separate zip or repo.

## Example: What Your Folder Should Look Like

```
chatbot/
├── faq_data.csv          (or however you store your Q&A pairs)
├── chatbot_engine.py       (your core logic)
├── chatbot_api.py          (FastAPI endpoint, if you're making one)
└── README.md               (explains your part)
```

## Quick Checklist Before You Push

- [ ] Folder is named `chatbot`, sitting directly in the repo root
- [ ] No personal name used as a folder name
- [ ] Your code runs without errors when tested fresh
- [ ] You've added a short README inside your folder
- [ ] You've told Nikhil once it's pushed, so the main README status
      table can be updated (Support Chatbot: In progress -> Done)

If anything is unclear, ask Nikhil before pushing — better to check once
than to restructure later.
