# Pattern: Slide Show Countdown Timer (VBA)

## What It Does

A PowerPoint VBA countdown timer that updates a named shape (`TimerBox`) during
slide show mode. Supports two modes:

- **Duration** — count down from a user-entered length (default/max: `2:55:00`)
- **End time** — count down to a clock time (e.g. `3:30 PM`)

Uses the Windows `SetTimer` API with a callback (`TimerProc`) instead of
`Application.OnTime`, so ticks continue reliably while the slide show is
running.

## Setup

1. Save the deck as `.pptm` (macro-enabled).
2. Import `modCountdownTimer.bas` into the VBA project (or paste the module).
3. Paste the event handlers from `ThisPresentation.cls` into the
   **ThisPresentation** module in the VBA editor (under the presentation
   object, not a standard module). These call `StopCountdown` when the slide
   show ends or the file closes, so the Windows timer doesn't keep firing.
4. Import `cPPTEvents.cls` and wire it to `Application` so slide show
   begin/end fire automatically. A class with `WithEvents` must be
   instantiated and connected — add this to `ThisPresentation` (or a standard
   init module):

   ```vba
   Public gPPTEvents As cPPTEvents

   Private Sub Presentation_Open()
       Set gPPTEvents = New cPPTEvents
       Set gPPTEvents.App = Application
   End Sub
   ```

   `cPPTEvents` calls `StartCountdown` when slide show begins (shows input
   prompts) and `StopCountdown` when it ends. To start silently with the
   default duration instead, change the `App_SlideShowBegin` handler.
5. Add a text box named **`TimerBox`** on the Slide Master (or on individual
   slides / layouts).
6. Enable **Trust access to the VBA project object model** if you need to
   export/import modules programmatically.
7. Optionally wire additional presentation events (e.g.
   `SlideShowNextSlide`) to call `RefreshTimerOnCurrentSlide` so the display
   stays in sync when advancing slides.

## Public Entry Points

| Macro | Purpose |
|---|---|
| `StartCountdown` | Prompt for duration or end time, validate, start timer |
| `StopCountdown` | Stop the running countdown |
| `ResetCountdownDisplay` | Set display to `00:00:00` without starting |
| `RefreshTimerOnCurrentSlide` | Re-render remaining time on the current slide |

Assign these to shapes/buttons or run from the VBA immediate window during
slide show.

## Key Design Choices

- **Windows timer callback** — `AddressOf TimerProc` fires every second
  without blocking the UI thread the way some `OnTime` loops can.
- **Shape lookup cascade** — searches current slide shapes, then layout
  shapes, then master shapes, so the timer works across varied deck layouts.
- **Dual text frame write** — tries both `TextFrame` and `TextFrame2` because
  some shape types behave differently.
- **Hard max duration** — `MAX_DURATION_SECONDS` caps countdown at 2:55:00 in
  both duration and end-time modes.
- **Presentation event cleanup** — `ThisPresentation` handlers stop the timer
  on slide show end and file close, preventing orphaned `SetTimer` callbacks.
- **Application-level events** — `cPPTEvents` listens at the `Application`
  level so `StartCountdown` runs when any slide show begins (requires
  `Presentation_Open` wiring shown above).

## Common Pitfalls

- **Slide show must be running** before `StartCountdown` — the macro checks
  `SlideShowActive()` and exits with a message if not.
- **Missing shape name** — if nothing is named exactly `TimerBox`, the timer
  won't start. Name the shape in Selection Pane, not just the placeholder
  label text.
- **`SetTimerText` comment vs. code** — the lookup tries the current slide
  first, then the master. If a slide hides background graphics, put
  `TimerBox` on that slide directly.
- **End-time rollover** — if the entered clock time is earlier than `Now`,
  the code assumes "tomorrow" (`Date + 1 + TimeValue`).
- **32-bit vs 64-bit** — `#If VBA7 Then` block declares `PtrSafe` APIs for
  64-bit Office; the `#Else` branch covers older 32-bit installs.
- **`WithEvents` not firing** — if `cPPTEvents` never triggers, the instance
  was never created or `App` was never set. Confirm `Presentation_Open` runs
  (open the file fresh, not just edit in VBA).
- **Duplicate stop handlers** — both `ThisPresentation` and `cPPTEvents`
  call `StopCountdown` on exit; that's safe (`StopCountdown` is idempotent).

## Files

- `modCountdownTimer.bas` — timer logic and public macros
- `ThisPresentation.cls` — presentation event handlers (cleanup on exit)
- `cPPTEvents.cls` — application-level slide show begin/end hooks
