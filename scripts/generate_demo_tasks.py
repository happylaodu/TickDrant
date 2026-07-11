"""Generate demo tasks JSON for App Store screenshots.

Produces `docs/demo-tasks.json` with 8 tasks balanced across the four
Eisenhower quadrants, with due dates offset from NOW. Run this right
before taking screenshots so the countdown timers show fresh values.

Import via Settings → Data → Import Tasks → Replace All.

Quadrant thresholds (from QuadrantConfig):
  - important: effectiveImportance >= 5
  - urgent:    due within 5 days
"""
from __future__ import annotations

import json
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path


def iso(dt: datetime) -> str:
    """ISO8601 with Z suffix, no microseconds — matches Swift .iso8601 output."""
    return dt.replace(microsecond=0).isoformat().replace("+00:00", "Z")


def task(name: str, due_offset: timedelta | None, importance: int,
         recurring: tuple[int, str] | None = None,
         completed_offset: timedelta | None = None) -> dict:
    now = datetime.now(timezone.utc)
    entry = {
        "id": str(uuid.uuid4()).upper(),
        "name": name,
        "importance": importance,
        "isRecurring": recurring is not None,
        "recurrenceValue": recurring[0] if recurring else 1,
        "recurrenceUnit": recurring[1] if recurring else "Days",
        "completed": completed_offset is not None,
    }
    if due_offset is not None:
        entry["dueDateTime"] = iso(now + due_offset)
    if completed_offset is not None:
        entry["completedDateTime"] = iso(now + completed_offset)
    return entry


TASKS = [
    # Q1 — Important & Urgent (top-right, red)
    task("Return vendor contract",   timedelta(hours=-3), importance=9),   # OVERDUE
    task("Thursday board deck",      timedelta(hours=6),  importance=7),

    # Q2 — Important & Not Urgent (top-left, green)
    task("Perf review self-assessment", timedelta(days=12), importance=9),
    task("5-year strategy memo",        timedelta(days=25), importance=6),

    # Q3 — Not Important & Urgent (bottom-right, orange)
    task("Reply to conference invite",  timedelta(hours=4), importance=3),
    task("Weekly team 1:1s",            timedelta(days=3),  importance=4,
         recurring=(1, "Weeks")),

    # Q4 — Not Important & Not Urgent (bottom-left, gray)
    task("Reorganize photos",           timedelta(days=40), importance=2),
    task("Card statement review",       timedelta(days=20), importance=3,
         recurring=(1, "Months")),

    # Completed — show up in the "Completed" tab with punctuality labels
    task("Submit Q2 expense report",       due_offset=timedelta(days=-1),
         importance=6, completed_offset=timedelta(days=-3)),   # done 2 days early
    task("File Q1 taxes",                  due_offset=timedelta(days=-4),
         importance=8, completed_offset=timedelta(days=-7)),   # done 3 days early
    task("Renew driver's license",         due_offset=timedelta(days=-7),
         importance=7, completed_offset=timedelta(days=-7)),   # done on time
    task("Prep quarterly review agenda",   due_offset=timedelta(days=-14),
         importance=6, completed_offset=timedelta(days=-14)),  # done on time
    task("Book flight to NYC",             due_offset=timedelta(days=-6),
         importance=5, completed_offset=timedelta(days=-11)),  # done 5 days early
    task("Send birthday card to Mom",      due_offset=timedelta(days=-12),
         importance=5, completed_offset=timedelta(days=-11)),  # done 1 day overdue
    task("Book dentist appointment",       due_offset=timedelta(days=-10),
         importance=4, completed_offset=timedelta(days=-8)),   # done 2 days overdue
]

OUT = Path(__file__).resolve().parent.parent / "docs" / "demo-tasks.json"


def main() -> None:
    OUT.write_text(json.dumps(TASKS, indent=2, sort_keys=True))
    print(f"wrote {OUT} ({len(TASKS)} tasks)")


if __name__ == "__main__":
    main()
