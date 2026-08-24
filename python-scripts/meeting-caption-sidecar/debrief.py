"""Prompt builders and optional AI calls for Pulse and End Meeting."""

from __future__ import annotations

import os
import urllib.error
import urllib.request
from dataclasses import dataclass


PULSE_PROMPT = """You are helping someone follow a live work meeting.

Return EXACTLY two short bullet points in plain English:
1) What they are discussing right now
2) Any decision or action item mentioned in this excerpt (or say "None yet")

Rules:
- Max 2 bullets total
- Plain language, no jargon unless you briefly explain it
- Do not invent facts that are not in the text

Meeting topic (optional): {topic}

Recent caption text:
{captions}
"""


END_PROMPT = """You are writing a meeting debrief for someone who struggles to digest meetings live.

Use ONLY the caption text and flagged terms below. If something is unclear, say so.

Return markdown with these sections:
## Summary
## Decisions
## Action items
## Flagged terms explained
## Follow-up questions I should ask
## Still unclear

Rules:
- Plain English
- Do not invent facts
- If a section has nothing supported by the text, write "None captured"

Meeting topic (optional): {topic}

Full caption log:
{captions}

Flagged terms:
{flags}
"""


@dataclass
class AiResult:
    text: str
    mode: str


def build_pulse_prompt(topic: str, captions: str) -> str:
    return PULSE_PROMPT.format(topic=topic or "Unknown", captions=captions or "(empty)")


def local_pulse_summary(captions: str, max_bullets: int = 2) -> str:
    """Instant catch-up from recent captions when no AI key is configured."""
    bodies: list[str] = []
    for line in captions.splitlines():
        if not line.startswith("["):
            continue
        idx = line.find("] ")
        body = line[idx + 2 :].strip() if idx >= 0 else line.strip()
        if body and (not bodies or bodies[-1] != body):
            bodies.append(body)

    if not bodies:
        return (
            "No captions captured yet.\n\n"
            "Wait 30–60 seconds after Start, then try Pulse again."
        )

    recent = bodies[-max_bullets:]
    bullets = "\n".join(f"• {text}" for text in recent)
    return (
        "Recent captions (instant catch-up):\n"
        f"{bullets}\n\n"
        "For plain-English summary: Pulse prompt copied to clipboard — "
        "paste into Copilot and read the 2-bullet answer."
    )


def build_end_prompt(topic: str, captions: str, flags: str) -> str:
    return END_PROMPT.format(
        topic=topic or "Unknown",
        captions=captions or "(empty)",
        flags=flags or "(none flagged)",
    )


def run_openai_prompt(prompt: str) -> AiResult:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError(
            "OPENAI_API_KEY is not set. Copy the prompt into Copilot/ChatGPT instead."
        )

    payload = (
        "{"
        '"model":"gpt-4o-mini",'
        '"messages":[{"role":"user","content":'
        + _json_string(prompt)
        + "}],"
        '"temperature":0.2'
        "}"
    ).encode("utf-8")

    request = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=payload,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"OpenAI request failed: {detail}") from exc

    text = _extract_openai_text(body)
    return AiResult(text=text, mode="openai")


def _json_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
    return f'"{escaped}"'


def _extract_openai_text(body: str) -> str:
    marker = '"content":'
    idx = body.find(marker)
    if idx < 0:
        raise RuntimeError("Could not parse OpenAI response.")

    rest = body[idx + len(marker) :].lstrip()
    if not rest.startswith('"'):
        raise RuntimeError("Unexpected OpenAI response shape.")

    chars: list[str] = []
    i = 1
    while i < len(rest):
        char = rest[i]
        if char == "\\":
            i += 1
            if i >= len(rest):
                break
            escape = rest[i]
            mapping = {"n": "\n", "r": "\r", "t": "\t", '"': '"', "\\": "\\"}
            chars.append(mapping.get(escape, escape))
        elif char == '"':
            break
        else:
            chars.append(char)
        i += 1

    return "".join(chars).strip()
