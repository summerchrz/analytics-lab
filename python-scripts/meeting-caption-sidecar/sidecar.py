"""Meeting Caption Sidecar — small always-on-top helper for live captions."""

from __future__ import annotations

import json
import os
import subprocess
import threading
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, scrolledtext, simpledialog

from capture import CaptionCapture, Region
from debrief import (
    build_end_prompt,
    build_pulse_prompt,
    local_pulse_summary,
    run_openai_prompt,
)
from session import SessionLog, default_data_dir


CONFIG_NAME = "config.json"


class RegionSelector(tk.Toplevel):
    """Drag a rectangle over the live caption area."""

    def __init__(self, master: tk.Tk, on_selected) -> None:
        super().__init__(master)
        self.on_selected = on_selected
        self.attributes("-fullscreen", True)
        self.attributes("-alpha", 0.25)
        self.configure(bg="black")
        self.canvas = tk.Canvas(self, cursor="cross", bg="black", highlightthickness=0)
        self.canvas.pack(fill="both", expand=True)

        self.start_x = 0
        self.start_y = 0
        self.rect_id = None

        self.canvas.bind("<ButtonPress-1>", self._on_press)
        self.canvas.bind("<B1-Motion>", self._on_drag)
        self.canvas.bind("<ButtonRelease-1>", self._on_release)
        self.bind("<Escape>", lambda _event: self.destroy())

        self.canvas.create_text(
            40,
            40,
            anchor="nw",
            fill="white",
            font=("Segoe UI", 16),
            text="Drag around your live caption box. Press Esc to cancel.",
        )

    def _on_press(self, event) -> None:
        self.start_x = event.x
        self.start_y = event.y
        if self.rect_id is not None:
            self.canvas.delete(self.rect_id)
        self.rect_id = self.canvas.create_rectangle(
            self.start_x,
            self.start_y,
            self.start_x,
            self.start_y,
            outline="#00ff88",
            width=3,
        )

    def _on_drag(self, event) -> None:
        if self.rect_id is None:
            return
        self.canvas.coords(self.rect_id, self.start_x, self.start_y, event.x, event.y)

    def _on_release(self, event) -> None:
        left = min(self.start_x, event.x)
        top = min(self.start_y, event.y)
        width = abs(event.x - self.start_x)
        height = abs(event.y - self.start_y)

        if width < 80 or height < 30:
            messagebox.showwarning(
                "Region too small",
                "Drag a larger box around the captions and try again.",
            )
            return

        region = Region(left=left, top=top, width=width, height=height)
        self.on_selected(region)
        self.destroy()


class SidecarApp:
    def __init__(self) -> None:
        self.root = tk.Tk()
        self.root.title("Meeting Caption Sidecar")
        self.root.geometry("360x420")
        self.root.attributes("-topmost", True)

        self.data_dir = default_data_dir()
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.config_path = self.data_dir / CONFIG_NAME

        self.region: Region | None = None
        self.session: SessionLog | None = None
        self.capture: CaptionCapture | None = None
        self.last_pulse = "Press Pulse when you fall behind."

        self.status_var = tk.StringVar(value="Pick a caption region to start.")
        self.topic_var = tk.StringVar(value="")

        self._build_ui()
        self._load_region()

    def _build_ui(self) -> None:
        header = tk.Label(
            self.root,
            textvariable=self.status_var,
            wraplength=330,
            justify="left",
            anchor="w",
        )
        header.pack(fill="x", padx=12, pady=(12, 6))

        topic_row = tk.Frame(self.root)
        topic_row.pack(fill="x", padx=12, pady=4)
        tk.Label(topic_row, text="Topic:").pack(side="left")
        tk.Entry(topic_row, textvariable=self.topic_var).pack(
            side="left", fill="x", expand=True, padx=(6, 0)
        )

        pulse_label = tk.Label(self.root, text="NOW (last Pulse):")
        pulse_label.pack(anchor="w", padx=12, pady=(8, 0))

        self.pulse_box = scrolledtext.ScrolledText(
            self.root, height=8, wrap="word", font=("Segoe UI", 10)
        )
        self.pulse_box.pack(fill="both", expand=True, padx=12, pady=6)
        self.pulse_box.insert("1.0", self.last_pulse)
        self.pulse_box.configure(state="disabled")

        button_row = tk.Frame(self.root)
        button_row.pack(fill="x", padx=12, pady=(0, 12))

        tk.Button(button_row, text="Set region", command=self.pick_region).pack(
            side="left", padx=(0, 6)
        )
        tk.Button(button_row, text="Start", command=self.start_capture).pack(
            side="left", padx=(0, 6)
        )
        tk.Button(button_row, text="Pulse", command=self.run_pulse).pack(
            side="left", padx=(0, 6)
        )
        tk.Button(button_row, text="?", command=self.flag_term).pack(
            side="left", padx=(0, 6)
        )
        tk.Button(button_row, text="End", command=self.end_meeting).pack(side="left")

    def _load_region(self) -> None:
        if not self.config_path.exists():
            return

        data = json.loads(self.config_path.read_text(encoding="utf-8"))
        self.region = Region.from_dict(data["region"])
        self.status_var.set(
            f"Saved caption region loaded ({self.region.width}x{self.region.height}). "
            "Click Start when the meeting begins."
        )

    def _save_region(self, region: Region) -> None:
        self.region = region
        payload = {"region": region.as_dict()}
        self.config_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        self.status_var.set(
            f"Caption region saved. Click Start when captions are visible."
        )

    def pick_region(self) -> None:
        RegionSelector(self.root, self._save_region)

    def start_capture(self) -> None:
        if self.region is None:
            messagebox.showinfo(
                "Region needed",
                "Click Set region first and drag a box around your caption area.",
            )
            return

        if self.capture is not None:
            messagebox.showinfo("Already running", "Capture is already running.")
            return

        self.session = SessionLog.start_new(self.data_dir)
        self.session.set_topic(self.topic_var.get().strip())

        self.capture = CaptionCapture(
            region=self.region,
            session=self.session,
            on_update=lambda _text: self.root.after(
                0, lambda: self.status_var.set("Capturing captions...")
            ),
            on_error=lambda err: self.root.after(
                0, lambda: self.status_var.set(f"Capture warning: {err}")
            ),
        )
        self.capture.start()
        self.status_var.set(f"Capturing → {self.session.path.name}")

    def _set_pulse_text(self, text: str) -> None:
        self.last_pulse = text
        self.pulse_box.configure(state="normal")
        self.pulse_box.delete("1.0", "end")
        self.pulse_box.insert("1.0", text)
        self.pulse_box.configure(state="disabled")

    def _copy_to_clipboard(self, text: str) -> None:
        self.root.clipboard_clear()
        self.root.clipboard_append(text)
        self.root.update()

    def _open_meeting_files(self, caption_path: Path, debrief_path: Path) -> None:
        """Open the debrief prompt and show session files after End."""
        try:
            os.startfile(debrief_path)
        except OSError:
            pass

        try:
            subprocess.run(
                ["explorer", "/select,", os.fspath(debrief_path)],
                check=False,
            )
        except OSError:
            pass

        self.status_var.set(
            f"Meeting files in {caption_path.parent.name} — debrief opened."
        )

    def run_pulse(self) -> None:
        if self.session is None:
            messagebox.showinfo("Start first", "Click Start after captions are visible.")
            return

        self.session.set_topic(self.topic_var.get().strip())
        recent = self.session.read_recent_text()
        prompt = build_pulse_prompt(self.session.topic, recent)

        # Always show something immediately in NOW (no API key required).
        self._set_pulse_text(local_pulse_summary(recent))
        self.status_var.set("Pulse: showing recent captions...")

        pulse_path = self.session.path.with_name(self.session.path.stem + "-pulse.md")
        pulse_path.write_text(prompt, encoding="utf-8")

        def worker() -> None:
            try:
                result = run_openai_prompt(prompt)
                self.root.after(0, lambda: self._set_pulse_text(result.text))
                self.root.after(
                    0, lambda: self.status_var.set("Pulse updated from AI.")
                )
            except RuntimeError:
                self.root.after(0, lambda: self._copy_to_clipboard(prompt))
                self.root.after(
                    0,
                    lambda: self.status_var.set(
                        "Pulse: recent captions shown. AI prompt copied — paste into Copilot."
                    ),
                )
                self.root.after(
                    0,
                    lambda: messagebox.showinfo(
                        "Pulse prompt copied",
                        "NOW shows your latest captions.\n\n"
                        "For plain-English bullets, paste into Copilot (Ctrl+V).\n\n"
                        f"Prompt also saved to:\n{pulse_path}",
                    ),
                )

        threading.Thread(target=worker, daemon=True).start()

    def flag_term(self) -> None:
        if self.session is None:
            messagebox.showinfo("Start first", "Click Start before flagging terms.")
            return

        term = simpledialog.askstring("Flag term", "Word or phrase you did not get:")
        if not term:
            return

        self.session.add_flag(term)
        self.status_var.set(f"Flagged: {term}")

    def end_meeting(self) -> None:
        if self.capture is not None:
            self.capture.stop()
            self.capture = None

        if self.session is None:
            messagebox.showinfo("Nothing to end", "Start a session first.")
            return

        self.session.set_topic(self.topic_var.get().strip())
        prompt = build_end_prompt(
            self.session.topic,
            self.session.read_all_text(),
            self.session.read_flags(),
        )
        debrief_path = self.session.path.with_name(self.session.path.stem + "-debrief.md")
        debrief_path.write_text(prompt, encoding="utf-8")
        caption_path = self.session.path
        output_path = caption_path.with_name(caption_path.stem + "-debrief-output.md")

        def worker() -> None:
            try:
                result = run_openai_prompt(prompt)
                output_path.write_text(result.text, encoding="utf-8")

                def show_ai_debrief() -> None:
                    self._open_meeting_files(caption_path, output_path)
                    self._set_pulse_text(result.text)
                    messagebox.showinfo(
                        "Debrief saved",
                        "AI debrief opened in your editor.\n"
                        "Explorer shows the output file.\n\n"
                        f"{output_path}",
                    )

                self.root.after(0, show_ai_debrief)
            except RuntimeError:
                def show_manual_debrief() -> None:
                    self._copy_to_clipboard(prompt)
                    self._open_meeting_files(caption_path, debrief_path)
                    messagebox.showinfo(
                        "Debrief prompt ready",
                        "Debrief prompt opened + copied to clipboard.\n"
                        "Paste into Copilot (Ctrl+V), then save the answer.\n\n"
                        f"Caption log:\n{caption_path}\n\n"
                        f"Debrief prompt:\n{debrief_path}",
                    )

                self.root.after(0, show_manual_debrief)

        threading.Thread(target=worker, daemon=True).start()
        self.status_var.set("Meeting ended. Building debrief...")
        self.session = None

    def run(self) -> None:
        self.root.mainloop()


if __name__ == "__main__":
    try:
        SidecarApp().run()
    except Exception as exc:  # noqa: BLE001 - show startup failures in a dialog
        root = tk.Tk()
        root.withdraw()
        messagebox.showerror(
            "Meeting Sidecar failed to start",
            f"{exc}\n\nTry launch-sidecar.bat to see more detail in a console window.",
        )
        raise
