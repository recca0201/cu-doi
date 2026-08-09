"""Tests for run_state.py — the run coordination layer that keeps long extractions
safe to drive from AI coding agents (lock, atomic status file, sentinels, poll codes)."""

import json
import os

from conftest import load_script_module

run_state = load_script_module("run_state")


def test_lock_blocks_duplicate_then_releases(tmp_path):
    d = tmp_path / "run"
    c1 = run_state.RunCoordinator(d)
    assert c1.acquire_lock() is None  # first acquire succeeds

    c2 = run_state.RunCoordinator(d)
    holder = c2.acquire_lock()  # second sees the live holder
    assert holder is not None
    assert holder["pid"] == os.getpid()

    c1.release_lock()
    c3 = run_state.RunCoordinator(d)
    assert c3.acquire_lock() is None  # reacquire after release


def test_stale_lock_is_reclaimed(tmp_path):
    d = tmp_path / "run"
    d.mkdir(parents=True)
    # A lock owned by a certainly-dead pid must be reclaimed, not block forever.
    (d / run_state.LOCK_FILENAME).write_text(json.dumps({"pid": 999999999, "acquired_at": 0}))
    c = run_state.RunCoordinator(d)
    assert c.acquire_lock() is None


def test_status_lifecycle_and_success_sentinel(tmp_path):
    d = tmp_path / "run"
    c = run_state.RunCoordinator(d)
    c.acquire_lock()
    c.start({"file_key": "ABC", "node_id": "1:2"})
    assert run_state.read_status(d)["phase"] == "starting"

    c.phase("Fetching node 1:2")
    assert "Fetching" in run_state.read_status(d)["phase"]

    c.finish(0, [str(d / "figma-spec.json")])
    assert (d / run_state.DONE_FILENAME).exists()
    status = run_state.read_status(d)
    assert status["done"] is True and status["exit_code"] == 0
    assert run_state.print_status(d) == 0  # complete -> exit 0


def test_fail_writes_failed_sentinel_and_exit_1(tmp_path):
    d = tmp_path / "run"
    c = run_state.RunCoordinator(d)
    c.acquire_lock()
    c.start({"file_key": "ABC"})
    c.fail("boom")
    assert (d / run_state.FAILED_FILENAME).exists()
    assert run_state.print_status(d) == 1


def test_status_codes_running_and_missing(tmp_path):
    # Missing run-status.json -> not-started -> exit 1
    assert run_state.print_status(tmp_path / "never") == 1

    # A run that started but has not finished -> exit 3 (running)
    d = tmp_path / "run"
    c = run_state.RunCoordinator(d)
    c.acquire_lock()
    c.start({"file_key": "ABC"})
    c.phase("Resolving styles")
    assert run_state.print_status(d) == 3


def test_status_file_is_always_valid_json(tmp_path):
    # Atomic writes must never leave a half-written status file for a polling reader.
    d = tmp_path / "run"
    c = run_state.RunCoordinator(d)
    c.acquire_lock()
    c.start({"file_key": "ABC"})
    for i in range(20):
        c.phase(f"phase-{i}")
        json.loads((d / run_state.STATUS_FILENAME).read_text())  # raises if partial
