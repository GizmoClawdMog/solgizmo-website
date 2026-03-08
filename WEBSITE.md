# GIZMO WEBSITE RULES — READ BEFORE TOUCHING ANYTHING

## Correct repo
~/.openclaw/workspace/solgizmo-website

## The ONE correct file
~/.openclaw/workspace/solgizmo-website/index.html

## Rules
- ALWAYS git pull before editing
- NEVER revert or replace index.html — only patch the specific element requested
- NEVER use index.backup.html, index.MASTER-BACKUP-20260307.html or any other backup file as a base
- Only edit the single element asked for, nothing else
- After editing: git add index.html && git commit -m "description" && git push
- Netlify auto-deploys on push — check netlify dashboard to confirm

## Common mistake
Gizmo keeps reverting to old backup files. DO NOT do this. Always start from current index.html.
