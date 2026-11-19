"""Time-saved model for day-by-day categorisation.

Manual:   M minutes per day page to categorise everything by hand.
Assisted: R minutes to review a pre-categorised page, plus C seconds per wrong suggestion fixed.
Saved per day = M - R - C * corrections / 60   (can be negative on a bad day).
"""

from __future__ import annotations

from statistics import mean

MANUAL_MIN = [2, 3, 4, 5]  # minutes/day to categorise by hand
REVIEW_MIN = [0.5, 1, 1.5, 2]  # minutes/day to scan an already categorised page
FIX_SEC = [10, 20, 30]  # seconds per correction
CENTRAL = {"manual": 4, "review": 1, "fix": 20}


def saved_per_day(errors: int, manual: float, review: float, fix: float) -> float:
    return manual - review - fix * errors / 60


def history_hours(days: list[dict], manual: float, review: float, fix: float) -> float:
    return sum(saved_per_day(d["errors"], manual, review, fix) for d in days) / 60


def forward_hours_per_year(errors_per_day: float, manual: float, review: float, fix: float) -> float:
    return 365 * saved_per_day(errors_per_day, manual, review, fix) / 60


def cumulative(days: list[dict], manual: float, review: float, fix: float) -> list[tuple[int, float]]:
    out, tot = [], 0.0
    for i, d in enumerate(days):
        tot += saved_per_day(d["errors"], manual, review, fix) / 60
        out.append((i, tot))
    return out


def rolling_errors(days: list[dict], window: int = 7) -> list[tuple[int, float]]:
    e = [d["errors"] for d in days]
    return [(i, mean(e[max(0, i - window + 1): i + 1])) for i in range(len(e))]
