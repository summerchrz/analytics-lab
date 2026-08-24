"""Screenshot + OCR loop for a fixed caption region."""

from __future__ import annotations

import asyncio
import threading
import time
from dataclasses import dataclass

import mss
from PIL import Image
from winocr import recognize_pil

from session import SessionLog


@dataclass(frozen=True)
class Region:
    left: int
    top: int
    width: int
    height: int

    def as_dict(self) -> dict[str, int]:
        return {
            "left": self.left,
            "top": self.top,
            "width": self.width,
            "height": self.height,
        }

    @classmethod
    def from_dict(cls, data: dict[str, int]) -> Region:
        return cls(
            left=int(data["left"]),
            top=int(data["top"]),
            width=int(data["width"]),
            height=int(data["height"]),
        )


def _text_from_ocr_result(result) -> str:
    """Windows OCR returns an OcrResult object, not plain text."""
    text = getattr(result, "text", None)
    if text:
        return str(text).strip()

    lines = getattr(result, "lines", None)
    if lines:
        parts = []
        for line in lines:
            line_text = getattr(line, "text", None)
            if line_text:
                parts.append(str(line_text))
        if parts:
            return " ".join(parts).strip()

    return ""


def ocr_image(image: Image.Image) -> str:
    async def run_ocr() -> str:
        result = await recognize_pil(image)
        return _text_from_ocr_result(result)

    return asyncio.run(run_ocr())


class CaptionCapture(threading.Thread):
    """Poll a screen region and append new caption text to the session log."""

    def __init__(
        self,
        region: Region,
        session: SessionLog,
        interval_seconds: float = 2.0,
        on_update=None,
        on_error=None,
    ) -> None:
        super().__init__(daemon=True)
        self.region = region
        self.session = session
        self.interval_seconds = interval_seconds
        self.on_update = on_update
        self.on_error = on_error
        self._stop_event = threading.Event()
        self._previous_raw = ""

    def stop(self) -> None:
        self._stop_event.set()

    def run(self) -> None:
        monitor = self.region.as_dict()

        with mss.mss() as screenshotter:
            while not self._stop_event.is_set():
                try:
                    shot = screenshotter.grab(monitor)
                    image = Image.frombytes(
                        "RGB", shot.size, shot.bgra, "raw", "BGRX"
                    )
                    raw_text = ocr_image(image).strip()
                    new_text = self._extract_new_text(self._previous_raw, raw_text)
                    self._previous_raw = raw_text

                    if new_text and self.session.append_caption(new_text):
                        if self.on_update:
                            self.on_update(new_text)
                except Exception as exc:  # noqa: BLE001 - surface OCR issues in UI
                    if self.on_error:
                        self.on_error(str(exc))

                time.sleep(self.interval_seconds)

    @staticmethod
    def _extract_new_text(previous: str, current: str) -> str:
        if not current:
            return ""

        previous_norm = " ".join(previous.split())
        current_norm = " ".join(current.split())

        if not previous_norm:
            return current_norm

        if current_norm == previous_norm:
            return ""

        if current_norm.startswith(previous_norm):
            return current_norm[len(previous_norm) :].strip()

        # Captions often refresh partially; keep the longest new suffix we can find.
        previous_tail = previous_norm[-80:]
        idx = current_norm.find(previous_tail)
        if idx >= 0:
            suffix = current_norm[idx + len(previous_tail) :].strip()
            if suffix:
                return suffix

        return current_norm
