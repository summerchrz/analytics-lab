# Meeting Caption Sidecar

Personal Windows helper for **live accessibility captions that disappear when a
Teams call ends**.

Saves caption text you already see on screen, helps you catch up mid-meeting
(**Pulse**), and builds a debrief prompt after hang-up (**End**).

- **No audio recording**
- **No Teams integration**
- **Local files only** (on your machine)
- **Optional AI** via clipboard + approved Copilot (or OpenAI API if policy allows)

---

## Who this is for

Anyone who:

- Uses **live captions** (accessibility setting) during video calls
- Struggles to digest meetings in real time
- Loses captions when the call ends
- Wants **personal working notes**, not official meeting minutes

---

## How it works

```
Live captions on your screen (Teams / Windows accessibility)
        ↓
Sidecar screenshots ONLY the caption box every ~2 seconds
        ↓
Windows OCR reads the text
        ↓
New lines appended to a local log file
        ↓
├─ Pulse (during)  → instant catch-up + optional Copilot prompt
└─ End (after)     → debrief prompt + opens files
```

| Piece | File | Job |
|---|---|---|
| Session log | `session.py` | Timestamped caption file + flagged terms |
| Caption capture | `capture.py` | Screenshot caption box → OCR → append new text |
| Debrief prompts | `debrief.py` | Pulse / End prompts; optional OpenAI call |
| Sidecar UI | `sidecar.py` | Always-on-top window with buttons |
| Launcher | `launch-sidecar.bat` | Double-click start (use for desktop shortcut) |

Data stays under:

```text
C:\Users\<you>\.meeting-sidecar\
  config.json
  sessions\
    meeting-YYYYMMDD-HHMMSS.md
    meeting-...-flags.md
    meeting-...-pulse.md
    meeting-...-debrief.md
    meeting-...-debrief-output.md   (only if OpenAI API key used)
```

---

## Consent and policy (read this first)

### What it is **not**

| Not this | Why |
|---|---|
| Hidden audio recorder | No microphone capture |
| Official meeting recording | Does not use Teams record/transcribe |
| Team-wide or shared system | Files stay on one person's PC |
| Official minutes | Personal notes; OCR can misread words |

### What it **is**

Saving text from **accessibility captions already displayed to you** — similar
to taking personal notes, but automated so captions survive after hang-up.

**Reasonable framing for a manager:**

> *Personal note-taking helper. I use live captions for accessibility. Captions
> vanish when the call ends, so this saves what I can see on my own screen to
> my own laptop — like automated notes for me, not a recording of the meeting.*

### Good practices

1. Treat output as **personal working notes**, not a distributed record
2. Keep session logs **local** unless employer policy says otherwise
3. Use **approved AI** (e.g. M365 Copilot) for work content — not public tools
   unless policy allows
4. Check **employer IT/policy** before use on sensitive meetings
5. Optional transparency: *"I use captions and personal notes to follow along"*

Colleagues and managers should confirm rules for their own organization.

---

## One-time setup (Windows)

### 1. Install Python 3.11+

Download: https://www.python.org/downloads/

During install, check **Add python to PATH**.

```powershell
python --version
```

### 2. Clone or copy this folder

```powershell
cd path\to\meeting-caption-sidecar
```

### 3. Create virtual environment and install deps

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

If PowerShell blocks activation (once per machine):

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### 4. Run the sidecar

```powershell
python sidecar.py
```

Or double-click **`launch-sidecar.bat`**.

### 5. Desktop shortcut (recommended)

1. Right-click Desktop → **New** → **Shortcut**
2. **Target:**

   ```text
   C:\full\path\to\meeting-caption-sidecar\launch-sidecar.bat
   ```

3. **Start in:**

   ```text
   C:\full\path\to\meeting-caption-sidecar
   ```

4. Name it **Meeting Sidecar**

---

## First-time calibration

Expect trial and error on region setup — this is normal.

1. Join a call (or test with any captioned audio) and turn on **live captions**
2. Open sidecar → **Set region** → drag a **small box only on caption text**
   - Not the whole Teams footer
   - Not the search bar
   - Not over the sidecar window itself
3. Move sidecar to **top or side** of screen
4. Click **Start**
5. After 30–60 seconds, open the newest file in:

   ```text
   C:\Users\<you>\.meeting-sidecar\sessions\
   ```

**Good capture:** spoken sentences (`Testing. Help this is me testing.`)

**Bad capture:** `Q Search`, `Set region Start Pulse` → region too large; redo
**Set region**

---

## Daily meeting routine

| When | Do this |
|---|---|
| Join meeting | Captions on (often your default) |
| Open app | Double-click **Meeting Sidecar** |
| First minute | Click **Start** |
| During | **Pulse** when lost · **?** for jargon · optional **Topic** |
| Hang up | Captions disappear — your log remains |
| After | **End** → debrief file opens + Explorer + clipboard for Copilot |

### Buttons

| Button | What it does |
|---|---|
| **Set region** | One-time drag box around caption area (redo if captions move) |
| **Start** | Begin saving captions to a new session file |
| **Pulse** | Shows recent captions in NOW box; copies AI prompt for Copilot |
| **?** | Flag a term you didn't understand |
| **Topic** | Optional 3-word subject anchor |
| **End** | Stop capture; build debrief; open files |

---

## AI options

### Option A — No API key (recommended for work)

Do not set any API key.

- **Pulse:** NOW box updates instantly; prompt copied → paste into Copilot
- **End:** debrief file opens; prompt copied → paste into Copilot

### Option B — OpenAI API key (optional)

Only if policy allows sending meeting text to that service.

```powershell
$env:OPENAI_API_KEY = "your-key-here"
python sidecar.py
```

Pulse and End call the API directly and save `-debrief-output.md`.

---

## Open session files quickly

**Win + R**, then paste:

```text
%USERPROFILE%\.meeting-sidecar\sessions
```

Optional: pin that folder to File Explorer Quick access for browsing old sessions.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Empty log | Region misses captions | **Set region** again with captions visible |
| `Q Search` / button labels in log | Region too big | Smaller box; move sidecar away from bottom |
| Garbled words | OCR noise | Larger caption font; slightly wider caption-only box |
| Nothing after hang-up | Forgot **Start** | Start in first minute of call |
| Pulse looked broken | No API key | NOW box should still update; paste prompt into Copilot |
| Capture warning / OCR error | Restart sidecar after code updates | Close and reopen via shortcut |
| Shortcut won't open | Wrong target path | Point shortcut at `launch-sidecar.bat` + set **Start in** |

---

## Build order (if learning Python)

1. Read `session.py` — file logging
2. Run **Start** only — confirm `.md` log fills
3. Read `capture.py` — screenshot + OCR loop
4. **Pulse** with clipboard mode
5. **End** debrief + auto-open files

---

## Share with a colleague

Give them this folder **without** `.venv` (they create their own). Minimum files:

```text
capture.py
debrief.py
session.py
sidecar.py
launch-sidecar.bat
requirements.txt
README.md
```

They should read **Consent and policy** above and check their own employer rules.

---

## Portfolio note

Pattern: **ephemeral on-screen text → durable local log → structured debrief**.

Never commit real meeting logs to git. Session files live only in
`~/.meeting-sidecar/sessions/`.

---

## v2 ideas

- Hotkeys (`Ctrl+Shift+P` for Pulse)
- Read Windows Live Captions via UI Automation (less OCR fragility)
- Local model (Ollama) for debrief without cloud
- Calendar reminder to open sidecar before meetings
