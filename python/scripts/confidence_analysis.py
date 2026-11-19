"""Which per-entry signals catch wrong suggestions in the day-by-day replay?

Run: uv run python scripts/confidence_analysis.py path/to/page.lepiter
(or set TT_LEPITER_PAGE). Results stay local; they describe personal data.
"""

import math
import sys
from pathlib import Path
from collections import Counter, defaultdict

from tt_suggest.features import Encoder
from tt_suggest.cli import DEFAULT_DATA
from tt_suggest.load import load
from tt_suggest.model import Suggester

_data = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DATA
if not _data:
    sys.exit("usage: confidence_analysis.py path/to/page.lepiter (or set TT_LEPITER_PAGE)")
E, T = load(Path(_data).expanduser())
model = Suggester(Encoder(T, "full"))
days = defaultdict(list)
for e in E:
    days[e.day].append(e)
order = sorted(days.values(), key=lambda es: min(e.start for e in es))

hist = defaultdict(Counter)  # description -> category counts from earlier days
rows = []  # per entry after warm-up
for di, es in enumerate(order):
    for e in es:
        sc = model.scores(e)
        c1, s1 = sc[0]
        s2 = sc[1][1]
        d = e.description.lower()
        h = hist[d]
        n = sum(h.values())
        # softmax over negative costs as a rough "probability"
        z = [math.exp(-s / 0.1) for _, s in sc]
        p1 = z[0] / sum(z)
        if di >= 30:
            rows.append({
                "wrong": c1 != e.category,
                "margin": s2 - s1,
                "p1": p1,
                "novel": n == 0,
                "ambig": n > 0 and h.most_common(1)[0][1] / n < 0.9,
                "lookup_disagree": n > 0 and h.most_common(1)[0][0] != c1,
                "day": di,
            })
    for e in es:
        model.learn(e)
        hist[e.description.lower()][e.category] += 1

N = len(rows)
W = sum(r["wrong"] for r in rows)
print(f"entries {N}, wrong {W} ({W / N:.2%}), days {len(order) - 30}")


def report(name, flag):
    f = [r for r in rows if flag(r)]
    caught = sum(r["wrong"] for r in f)
    print(f"{name:38s} flags {len(f) / N:6.1%} of entries ({len(f) / (len(order) - 30):4.1f}/day) | "
          f"error rate in flagged {caught / max(1, len(f)):6.1%} | catches {caught / W:6.1%} of errors")


report("novel description", lambda r: r["novel"])
report("ambiguous history (<90% one label)", lambda r: r["ambig"])
report("model disagrees with lookup", lambda r: r["lookup_disagree"])
report("novel OR ambiguous", lambda r: r["novel"] or r["ambig"])
report("novel OR ambiguous OR disagree", lambda r: r["novel"] or r["ambig"] or r["lookup_disagree"])
for q in (0.02, 0.05, 0.10):
    thr = sorted(r["margin"] for r in rows)[int(q * N)]
    report(f"lowest {q:.0%} margin (margin<{thr:.3f})", lambda r, t=thr: r["margin"] < t)
thr5 = sorted(r["margin"] for r in rows)[int(0.05 * N)]
report("novel OR ambiguous OR lowest-5% margin",
       lambda r: r["novel"] or r["ambig"] or r["margin"] < thr5)
print("\nerror rate by softmax p1 bucket:")
for lo, hi in ((0, .5), (.5, .8), (.8, .95), (.95, .99), (.99, 1.01)):
    b = [r for r in rows if lo <= r["p1"] < hi]
    if b:
        print(f"  p1 in [{lo:.2f},{hi:.2f}): {len(b):6d} entries, error {sum(r['wrong'] for r in b) / len(b):6.1%}")
