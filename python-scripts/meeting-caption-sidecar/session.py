"""Local session log for captured caption text."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path


def default_data_dir() -> Path:
    return Path.home() / ".meeting-sidecar"


@dataclass
class SessionLog:
    """Append-only caption log with timestamps."""

    path: Path
    flags_path: Path
    topic: str = ""
    _lines: list[str] = field(default_factory=list, init=False)

    @classmethod
    def start_new(cls, data_dir: Path | None = None) -> SessionLog:
        base = data_dir or default_data_dir()
        sessions_dir = base / "sessions"
        sessions_dir.mkdir(parents=True, exist_ok=True)

        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        path = sessions_dir / f"meeting-{stamp}.md"
        flags_path = sessions_dir / f"meeting-{stamp}-flags.md"

        session = cls(path=path, flags_path=flags_path)
        session.path.write_text(
            f"# Meeting session {stamp}\n\n", encoding="utf-8"
        )
        flags_path.write_text("# Flagged terms\n\n", encoding="utf-8")
        return session

    def append_caption(self, text: str) -> bool:
        cleaned = " ".join(text.split())
        if not cleaned:
            return False

        if self._lines and cleaned == self._lines[-1]:
            return False

        if self._lines and cleaned.startswith(self._lines[-1]):
            cleaned = cleaned[len(self._lines[-1]) :].strip()
            if not cleaned:
                return False

        stamp = datetime.now().strftime("%H:%M:%S")
        line = f"[{stamp}] {cleaned}"
        self._lines.append(cleaned)

        with self.path.open("a", encoding="utf-8") as handle:
            handle.write(f"{line}\n")

        return True

    def add_flag(self, term: str) -> None:
        cleaned = term.strip()
        if not cleaned:
            return

        stamp = datetime.now().strftime("%H:%M:%S")
        with self.flags_path.open("a", encoding="utf-8") as handle:
            handle.write(f"- [{stamp}] {cleaned}\n")

    def set_topic(self, topic: str) -> None:
        self.topic = topic.strip()

    def read_recent_text(self, max_chars: int = 3500) -> str:
        if not self.path.exists():
            return ""

        lines = self.path.read_text(encoding="utf-8").splitlines()
        body = [line for line in lines if line.startswith("[")]

        chunks: list[str] = []
        total = 0
        for line in reversed(body):
            if total + len(line) + 1 > max_chars:
                break
            chunks.append(line)
            total += len(line) + 1

        return "\n".join(reversed(chunks))

    def read_all_text(self) -> str:
        if not self.path.exists():
            return ""
        return self.path.read_text(encoding="utf-8")

    def read_flags(self) -> str:
        if not self.flags_path.exists():
            return ""
        return self.flags_path.read_text(encoding="utf-8")
