#!/usr/bin/env python3
"""
Run-state coordination for figma_client.py — makes long extractions safe to drive
from AI coding agents whose terminals may return before the command finishes
(GitHub Copilot's run_in_terminal, Cursor auto-backgrounding, Claude Code's 2-min
default timeout).

The problem this solves: when a harness hands control back to the agent mid-run with
no output, the agent cannot tell "still working" from "died". It then re-runs the
command (doubling Figma Tier-1 API load) or hand-rolls its own script. The incident
that motivated this: two concurrent extractions raced into temp/, plus a duplicated
figma-spec.md, because the agent never saw the first run finish.

The fix is a machine-readable ground truth on disk that any later poll can read:
  - run-status.json  — phase, pid, done flag, exit code, output paths (atomic writes)
  - .done / .failed  — terminal sentinel files with the exit code
  - .lock            — a second concurrent run for the same output exits fast instead
                       of starting a duplicate extraction

Everything here is Python standard library only (works on macOS and Windows) so the
skill keeps its zero-install contract.
"""

import json
import os
import sys
import threading
import time
from pathlib import Path
from typing import Optional


STATUS_FILENAME = "run-status.json"
LOCK_FILENAME = ".figma-run.lock"
DONE_FILENAME = ".done"
FAILED_FILENAME = ".failed"

# A lock older than this (seconds) is treated as stale and reclaimed. Extraction of a
# very large board can legitimately take a few minutes; 30 min is comfortably beyond
# any real run while still recovering from a crashed process that never released it.
STALE_LOCK_SECONDS = 30 * 60


def _now() -> float:
    return time.time()


def _iso(ts: float) -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(ts))


def _atomic_write(path: Path, text: str) -> None:
    """Write via a temp file + rename so a polling reader never sees a half-written file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + f".tmp.{os.getpid()}")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def _pid_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True  # exists, owned by someone else
    except OSError:
        return False
    return True


class RunCoordinator:
    """Owns the lock + status file + sentinels for one extraction run directory."""

    def __init__(self, run_dir: Path):
        self.run_dir = Path(run_dir)
        self.status_path = self.run_dir / STATUS_FILENAME
        self.lock_path = self.run_dir / LOCK_FILENAME
        self.done_path = self.run_dir / DONE_FILENAME
        self.failed_path = self.run_dir / FAILED_FILENAME
        self._held_lock = False
        self._status = {
            "run_id": str(os.getpid()),
            "pid": os.getpid(),
            "phase": "starting",
            "progress_note": "",
            "done": False,
            "exit_code": None,
            "outputs": [],
        }

    # ── lock ──────────────────────────────────────────────────────────────
    def acquire_lock(self) -> Optional[dict]:
        """Try to claim the run directory.

        Returns None on success (lock now held), or a dict describing the holder
        when another live, non-stale run already owns it. Uses O_CREAT|O_EXCL so the
        check-and-create is atomic and portable across macOS/Windows (flock is
        POSIX-only and would break the cross-platform contract).
        """
        self.run_dir.mkdir(parents=True, exist_ok=True)
        payload = json.dumps({"pid": os.getpid(), "acquired_at": _now()})
        try:
            fd = os.open(str(self.lock_path), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            with os.fdopen(fd, "w") as f:
                f.write(payload)
            self._held_lock = True
            return None
        except FileExistsError:
            holder = self._read_lock()
            if self._lock_is_stale(holder):
                # Reclaim: previous owner died without releasing, or lock is ancient.
                try:
                    os.replace(self.lock_path, self.lock_path.with_suffix(".stale"))
                except OSError:
                    pass
                return self.acquire_lock()
            return holder or {"pid": None, "acquired_at": None}

    def _read_lock(self) -> Optional[dict]:
        try:
            return json.loads(self.lock_path.read_text())
        except (OSError, ValueError):
            return None

    def _lock_is_stale(self, holder: Optional[dict]) -> bool:
        if not holder:
            return True
        pid = holder.get("pid") or 0
        acquired = holder.get("acquired_at") or 0
        if not _pid_alive(int(pid)):
            return True
        if _now() - float(acquired) > STALE_LOCK_SECONDS:
            return True
        return False

    def release_lock(self) -> None:
        if self._held_lock:
            try:
                self.lock_path.unlink()
            except OSError:
                pass
            self._held_lock = False

    # ── status ────────────────────────────────────────────────────────────
    def start(self, meta: dict) -> None:
        self._status.update(meta)
        self._status["started_at"] = _iso(_now())
        self._write_status("starting")

    def phase(self, name: str, note: str = "") -> None:
        self._status["phase"] = name
        self._status["progress_note"] = note
        self._write_status(name)

    def finish(self, exit_code: int, outputs: list) -> None:
        self._status["done"] = True
        self._status["exit_code"] = exit_code
        self._status["outputs"] = outputs
        self._status["phase"] = "complete" if exit_code == 0 else "failed"
        self._write_status(self._status["phase"])
        sentinel = self.done_path if exit_code == 0 else self.failed_path
        _atomic_write(sentinel, json.dumps({"exit_code": exit_code, "at": _iso(_now())}))

    def fail(self, reason: str) -> None:
        self._status["progress_note"] = reason
        self.finish(1, self._status.get("outputs", []))

    def _write_status(self, _phase: str) -> None:
        self._status["updated_at"] = _iso(_now())
        try:
            _atomic_write(self.status_path, json.dumps(self._status, indent=2))
        except OSError:
            pass  # never let status bookkeeping crash the actual extraction


class Heartbeat:
    """Emit one stderr line every `interval` seconds so no phase is silent for long.

    Agents interpret a long silence as a hang. A steady, low-volume pulse (phase name
    + elapsed seconds) keeps them patient without flooding the 30k-char output budget
    that Claude Code truncates at. `bump()` lets callers refresh the phase label.
    """

    def __init__(self, interval: float = 20.0, emit=None):
        self.interval = interval
        self._emit = emit or (lambda msg: print(msg, file=sys.stderr, flush=True))
        self._phase = "working"
        self._start = _now()
        self._stop = threading.Event()
        self._thread: Optional[threading.Thread] = None

    def bump(self, phase: str) -> None:
        self._phase = phase

    def _run(self) -> None:
        while not self._stop.wait(self.interval):
            elapsed = int(_now() - self._start)
            self._emit(f"[figma-design] still working: {self._phase} ({elapsed}s elapsed)")

    def start(self) -> "Heartbeat":
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()
        return self

    def stop(self) -> None:
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=1)


def read_status(run_dir: Path) -> dict:
    """Read a run's status for the `--status` poll command. Missing file => not-started."""
    status_path = Path(run_dir) / STATUS_FILENAME
    try:
        return json.loads(status_path.read_text())
    except FileNotFoundError:
        return {"phase": "not-started", "done": False, "exit_code": None, "outputs": []}
    except (OSError, ValueError):
        return {"phase": "unreadable", "done": False, "exit_code": None, "outputs": []}


def print_status(run_dir: Path) -> int:
    """Print a human line + machine JSON for a run. Exit code encodes state for agents:
    0 = complete & succeeded, 3 = still running, 1 = failed / not started / unreadable.
    """
    status = read_status(run_dir)
    phase = status.get("phase")
    done = status.get("done")
    note = status.get("progress_note") or ""
    if done and status.get("exit_code") == 0:
        human, code = f"COMPLETE — outputs: {status.get('outputs')}", 0
    elif done:
        human, code = f"FAILED — {note}", 1
    elif phase in ("not-started", "unreadable"):
        human, code = f"{phase.upper()} (no run-status.json in {run_dir})", 1
    else:
        human, code = f"RUNNING — phase: {phase} {('(' + note + ')') if note else ''}", 3
    print(f"[figma-design] {human}", file=sys.stderr, flush=True)
    print(json.dumps(status), flush=True)
    return code
