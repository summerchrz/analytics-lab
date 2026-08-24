# Meeting Caption Sidecar — quick setup checklist

Copy-paste checklist for first install. Full context: [README.md](README.md).

---

## Prerequisites

- [ ] Windows 10/11
- [ ] Python 3.11+ with **Add to PATH**
- [ ] Live captions enabled for your meetings (accessibility or Teams)

---

## Install (once)

```powershell
cd path\to\meeting-caption-sidecar

python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Test run:

```powershell
python sidecar.py
```

---

## Desktop shortcut (once)

| Field | Value |
|---|---|
| Target | `...\meeting-caption-sidecar\launch-sidecar.bat` |
| Start in | `...\meeting-caption-sidecar` |
| Name | Meeting Sidecar |

---

## Calibrate region (once, redo if captions move)

- [ ] Captions visible on screen
- [ ] Sidecar moved to top/side (not over caption bar)
- [ ] **Set region** → small box **only on caption text**
- [ ] **Start** → wait 30s → check `%USERPROFILE%\.meeting-sidecar\sessions\` for real sentences

---

## Every meeting

- [ ] Double-click **Meeting Sidecar**
- [ ] **Start** in first minute
- [ ] **Pulse** when lost
- [ ] **?** for jargon
- [ ] **End** after hang-up → paste debrief into Copilot

---

## Policy reminder

Personal notes from captions you already see. Not audio recording. Not official
minutes. Keep logs local. Use approved AI for work content.
