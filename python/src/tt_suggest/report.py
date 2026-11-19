"""Render results.json into a single static HTML page with inline SVG charts."""

from __future__ import annotations

import html
from pathlib import Path
from statistics import mean, median

from tt_suggest import savings as sv

W, H = 760, 300
M = {"l": 48, "r": 150, "t": 16, "b": 32}  # right margin holds direct labels

SERIES = ["var(--s1)", "var(--s2)", "var(--s3)", "var(--s4)"]
BASE = "var(--baseline)"


def _esc(s) -> str:
    return html.escape(str(s))


def _pct(v: float, d: int = 1) -> str:
    return f"{100 * v:.{d}f}%"


def find(res: dict, name: str, scenario: str) -> dict:
    return next(r for r in res["runs"] if r["name"] == name and r["scenario"] == scenario)


# ---------------------------------------------------------------- charts
def line_chart(res: dict, series: list[dict], metric: str, y0: float, y1: float, title: str,
               dates: list[str] | None = None, split: bool = True, yfmt=None, unit: str = "entry",
               hline: tuple[float, str] | None = None) -> str:
    """series: {label, run | points, color, dashed}. x = index into `dates` (entries by default)."""
    dates = dates or res["dates"]
    n = len(dates)
    tipfmt = yfmt or _pct
    yfmt = yfmt or (lambda v: f"{100 * v:.0f}%")
    pw, ph = W - M["l"] - M["r"], H - M["t"] - M["b"]

    def x(i):
        return M["l"] + pw * i / (n - 1)

    def y(v):
        return M["t"] + ph * (1 - (min(max(v, y0), y1) - y0) / (y1 - y0))

    out = [f'<svg viewBox="0 0 {W} {H}" role="img" aria-label="{_esc(title)}">']
    # grid + y labels
    steps = 5
    for k in range(steps + 1):
        v = y0 + (y1 - y0) * k / steps
        out.append(f'<line class="grid" x1="{M["l"]}" x2="{M["l"] + pw}" y1="{y(v):.1f}" y2="{y(v):.1f}"/>')
        out.append(f'<text class="tick" x="{M["l"] - 6}" y="{y(v) + 4:.1f}" text-anchor="end">{yfmt(v)}</text>')
    # month ticks
    last = None
    for i, d in enumerate(dates):
        ym = d[:7]
        if ym != last and int(d[5:7]) % 2 == 1:
            out.append(f'<line class="axis" x1="{x(i):.1f}" x2="{x(i):.1f}" y1="{M["t"] + ph}" y2="{M["t"] + ph + 4}"/>')
            out.append(f'<text class="tick" x="{x(i):.1f}" y="{M["t"] + ph + 18}" text-anchor="middle">{d[:7]}</text>')
        last = ym
    out.append(f'<line class="axis" x1="{M["l"]}" x2="{M["l"] + pw}" y1="{M["t"] + ph}" y2="{M["t"] + ph}"/>')
    if split:  # warm-start split marker
        s = res["meta"]["split_index"]
        out.append(f'<line class="split" x1="{x(s):.1f}" x2="{x(s):.1f}" y1="{M["t"]}" y2="{M["t"] + ph}"/>')
        out.append(f'<text class="tick" x="{x(s) + 4:.1f}" y="{M["t"] + 12}">20% warm-start split</text>')
    if hline:
        hv, hl = hline
        out.append(f'<line class="split" x1="{M["l"]}" x2="{M["l"] + pw}" y1="{y(hv):.1f}" y2="{y(hv):.1f}"/>')
        out.append(f'<text class="tick" x="{M["l"] + pw - 4}" y="{y(hv) - 5:.1f}" text-anchor="end">{_esc(hl)}</text>')
    # series
    label_ys = []
    for srs in series:
        pts = srs["points"] if "points" in srs else srs["run"]["rolling"][metric]
        if not pts:
            continue
        d = " ".join(f"{x(i):.1f},{y(v):.1f}" for i, v in pts)
        dash = ' stroke-dasharray="5 4"' if srs.get("dashed") else ""
        out.append(f'<polyline fill="none" stroke="{srs["color"]}" stroke-width="2"{dash} points="{d}"/>')
        # invisible hover targets every few points
        for i, v in pts[::3]:
            out.append(f'<circle class="hit" cx="{x(i):.1f}" cy="{y(v):.1f}" r="7">'
                       f'<title>{_esc(srs["label"])}: {tipfmt(v)} ({dates[i]}, {unit} {i})</title></circle>')
        label_ys.append([y(pts[-1][1]), srs])
    # direct labels at line ends, de-collided
    label_ys.sort(key=lambda t: t[0])
    for k in range(1, len(label_ys)):
        if label_ys[k][0] - label_ys[k - 1][0] < 14:
            label_ys[k][0] = label_ys[k - 1][0] + 14
    for ly, srs in label_ys:
        dash = ' stroke-dasharray="3 2"' if srs.get("dashed") else ""
        out.append(f'<line x1="{M["l"] + pw + 4}" x2="{M["l"] + pw + 16}" y1="{ly:.1f}" y2="{ly:.1f}" '
                   f'stroke="{srs["color"]}" stroke-width="2"{dash}/>')
        out.append(f'<text class="lbl" x="{M["l"] + pw + 20}" y="{ly + 4:.1f}">{_esc(srs["label"])}</text>')
    out.append("</svg>")
    legend = "".join(
        f'<span class="key"><i style="border-color:{s["color"]};border-top-style:{"dashed" if s.get("dashed") else "solid"}"></i>'
        f'{_esc(s["label"])}</span>' for s in series)
    return f'<figure><figcaption>{_esc(title)}</figcaption>{out and "".join(out)}<div class="legend">{legend}</div></figure>'


def hbar_chart(rows: list[tuple[str, float, str]], title: str, xmax: float = 1.0, note: str = "") -> str:
    bh, gap = 18, 6
    lw = 190
    pw = W - lw - 60
    h = len(rows) * (bh + gap) + 24
    out = [f'<svg viewBox="0 0 {W} {h}" role="img" aria-label="{_esc(title)}">']
    for k in range(5):
        gx = lw + pw * k / 4
        out.append(f'<line class="grid" x1="{gx:.1f}" x2="{gx:.1f}" y1="0" y2="{h - 20}"/>')
        out.append(f'<text class="tick" x="{gx:.1f}" y="{h - 6}" text-anchor="middle">{100 * xmax * k / 4:.0f}%</text>')
    for j, (label, v, color) in enumerate(rows):
        y = j * (bh + gap)
        w = max(1.0, pw * v / xmax)
        out.append(f'<text class="lbl" x="{lw - 8}" y="{y + bh - 5}" text-anchor="end">{_esc(label)}</text>')
        out.append(f'<path d="M{lw},{y} h{w - 4:.1f} a4,4 0 0 1 4,4 v{bh - 8} a4,4 0 0 1 -4,4 h{-(w - 4):.1f} z" fill="{color}">'
                   f'<title>{_esc(label)}: {_pct(v)}</title></path>')
        out.append(f'<text class="val" x="{lw + w + 6:.1f}" y="{y + bh - 5}">{_pct(v)}</text>')
    out.append("</svg>")
    cap = f'<figcaption>{_esc(title)}</figcaption>'
    return f'<figure>{cap}{"".join(out)}{f"<p class=note>{note}</p>" if note else ""}</figure>'


# ---------------------------------------------------------------- tables
def summary_table(res: dict, rows: list[tuple[str, str, str]], cold: bool = True) -> str:
    head = ["Model", "Top-1", "Top-3", "Right root", "Slot hit@3"] + (["Cold top-1", "Cold right root"] if cold else [])
    out = ["<table><thead><tr>" + "".join(f"<th>{h}</th>" for h in head) + "</tr></thead><tbody>"]
    for label, name, scen in rows:
        s = find(res, name, scen)["summary"]["tail"]
        cells = [s["top1"], s["top3"], s["root"], s["slot_hit3"]] + ([s["cold_top1"], s["cold_root"]] if cold else [])
        out.append(f"<tr><td>{_esc(label)}</td>" + "".join(f"<td>{_pct(c)}</td>" for c in cells) + "</tr>")
    out.append("</tbody></table>")
    return "".join(out)


def category_table(res: dict, key: str, limit: int | None = None, worst: bool = False) -> str:
    rows = res["per_category"][key]
    tree = res["tree"]
    if worst:
        rows = sorted([r for r in rows if r[1] >= 10], key=lambda r: r[2])[:limit]
    elif limit:
        rows = rows[:limit]
    out = ["<table><thead><tr><th>Category</th><th>Path</th><th>Entries</th><th>Recall</th><th>Most common wrong guess</th></tr></thead><tbody>"]
    for c, n, rec, wrong in rows:
        out.append(f"<tr><td>{_esc(c)}</td><td class=muted>{_esc(' › '.join(tree[c]))}</td><td>{n}</td>"
                   f"<td>{_pct(rec)}</td><td>{_esc(wrong)}</td></tr>")
    out.append("</tbody></table>")
    return "".join(out)



def daily_section(res: dict) -> str:
    days = res.get("daily")
    if not days:
        return ""
    dates = [d["date"] for d in days]
    nd = len(days)
    last90 = days[-90:]
    e_all = mean(d["errors"] for d in days)
    e90 = mean(d["errors"] for d in last90)
    e_first30 = mean(d["errors"] for d in days[:30])
    zero90 = sum(d["errors"] == 0 for d in last90) / len(last90)
    n_day = median(d["n"] for d in days)
    tot_err = sum(d["errors"] for d in days)
    rescued = (tot_err - sum(d["errors_top3"] for d in days)) / tot_err
    c = sv.CENTRAL
    span_days = (__import__("datetime").date.fromisoformat(dates[-1]) - __import__("datetime").date.fromisoformat(dates[0])).days + 1

    hm = lambda h: f"{h:.1f} h"  # noqa: E731

    errs = line_chart(res, [
        {"label": "Corrections/day (7-day avg)", "points": sv.rolling_errors(days), "color": SERIES[0]},
    ], "", 0, 6, "Corrections needed per day page, model learning from each finished day (dotted: your estimate, 0.5/day)",
        dates=dates, split=False, unit="day", yfmt=lambda v: f"{v:.1f}",
        hline=(0.5, ""))

    cum_series = [
        {"label": f"Manual {m} min/day", "points": sv.cumulative(days, m, c["review"], c["fix"]), "color": SERIES[k]}
        for k, m in enumerate(sorted(sv.MANUAL_MIN, reverse=True))
    ]
    hi = max(p[1] for srs in cum_series for p in srs["points"])
    lo = min(0, min(p[1] for srs in cum_series for p in srs["points"]))
    cum = line_chart(res, cum_series, "", lo, 5 * __import__("math").ceil(hi / 5),
                     f"Cumulative hours saved since {dates[0]} (review {c['review']} min/day, {c['fix']} s per correction)",
                     dates=dates, split=False, unit="day", yfmt=lambda v: f"{round(v) or 0:.0f} h")

    def grid(fn, fmt, fix) -> str:
        head = "".join(f"<th>Review {r} min</th>" for r in sv.REVIEW_MIN)
        rows = []
        for m in sv.MANUAL_MIN:
            cells = "".join(f"<td>{fmt(fn(m, r, fix))}</td>" for r in sv.REVIEW_MIN)
            rows.append(f"<tr><td>Manual {m} min/day</td>{cells}</tr>")
        return f"<table><thead><tr><th></th>{head}</tr></thead><tbody>{''.join(rows)}</tbody></table>"

    hist = grid(lambda m, r, f: sv.history_hours(days, m, r, f), hm, c["fix"])
    fwd = grid(lambda m, r, f: sv.forward_hours_per_year(e90, m, r, f), hm, c["fix"])
    sens = ", ".join(
        f"{f} s → {sv.forward_hours_per_year(e90, c['manual'], c['review'], f):.1f} h/yr" for f in sv.FIX_SEC)
    manual_total = {m: m * nd / 60 for m in sv.MANUAL_MIN}
    central_hist = sv.history_hours(days, c["manual"], c["review"], c["fix"])
    central_fwd = sv.forward_hours_per_year(e90, c["manual"], c["review"], c["fix"])

    return f"""
<h2>1. Day-by-day: how much time would it have saved?</h2>
<p>This matches how you categorise: one day page at a time. For each of the {nd} day pages ({dates[0]} → {dates[-1]}),
the model suggests every entry's category using only what it learned from <em>earlier</em> days. Every wrong top-1 suggestion
counts as one correction you'd make. Then the model learns the finished day. It starts from nothing on day 1.
The whole replay takes about 14 s.</p>
<div class="tiles">
<div class="tile"><b>{e90:.2f}</b><span>corrections per day, last 90 days (median page: {n_day:.0f} entries)</span></div>
<div class="tile"><b>{_pct(zero90, 0)}</b><span>of recent days need no correction at all</span></div>
<div class="tile"><b>{e_first30:.1f}</b><span>corrections/day in the first 30 days, while it learns</span></div>
<div class="tile"><b>{_pct(rescued, 0)}</b><span>of wrong suggestions have the right category in the top-3</span></div>
</div>
{errs}
<p>Over all days it averages {e_all:.2f} corrections/day. Recently it needs about one correction a day, a bit more than your
"one every other day" guess. It is high only at the very start (day 1 gets all {days[0]['errors']} entries wrong, day 2 {days[1]['errors']}),
and within about two weeks it's down to a few per day. Corrections cluster on days with new activities. After the first month, days with no new
descriptions average {mean(d['errors'] for d in days[30:] if d['cold'] == 0):.2f} corrections, and days with 2+ new ones average
{mean(d['errors'] for d in days[30:] if d['cold'] >= 2):.2f}.</p>

<h3>Time saved</h3>
<p>The model: <strong>saved per day = manual time − review time − corrections × seconds per fix</strong>. Reviewing means looking
over a page of about {n_day:.0f} mostly-correct entries, which is cheaper than categorising from scratch. The central assumption is
{c['manual']} min manual vs {c['review']} min review + {c['fix']} s per fix. The tables vary the two numbers you're least sure about.</p>
{cum}
<h3>Since the beginning ({nd} tracked days over {span_days} calendar days)</h3>
<p>Manual categorising cost you about {hm(manual_total[2])}–{hm(manual_total[5])} in total (2–5 min/day).
Hours saved if suggestions had been on from day 1 (corrections at {c['fix']} s each):</p>
<div class="scroll">{hist}</div>
<h3>Going forward (hours per year, using the last-90-day rate of {e90:.2f} corrections/day)</h3>
<div class="scroll">{fwd}</div>
<p>With the central assumption, it would have saved about <strong>{hm(central_hist)}</strong> so far and saves about
<strong>{hm(central_fwd)} per year</strong> from here. It's sensitive mostly to how long the review takes, much less to
corrections, because there are so few of them. Per-correction cost at {c['manual']} min manual / {c['review']} min review: {sens}.
Assisted mode wins whenever manual time &gt; review time + about {e90 * c['fix'] / 60:.1f} min of corrections per day.</p>
<p class="note">The model learns only at the end of each day here, so a new activity that's repeated within the same day is
wrong every time. Learning on each save, as you go, would do slightly better. Only about a third of wrong suggestions have the right
category in the top-3, because most misses are new activities. So a one-click "alternatives" list wouldn't remove the need
for the normal category picker.</p>
"""

# ---------------------------------------------------------------- page
CSS = """
:root{--bg:#fcfcfb;--fg:#0b0b0b;--fg2:#52514e;--muted:#8a8984;--grid:#e6e5e0;--axis:#b5b4ae;--card:#ffffff;
--s1:#2a78d6;--s2:#eb6834;--s3:#1baf7a;--s4:#6250d6;--baseline:#8a8984;--accent:#2a78d6}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#1a1a19;--fg:#f0efec;--fg2:#c3c2b7;--muted:#8f8e86;
--grid:#2e2e2c;--axis:#55544f;--card:#222220;--s1:#3987e5;--s2:#d95926;--s3:#199e70;--s4:#9085e9;--baseline:#8f8e86;--accent:#3987e5}}
:root[data-theme="dark"]{--bg:#1a1a19;--fg:#f0efec;--fg2:#c3c2b7;--muted:#8f8e86;--grid:#2e2e2c;--axis:#55544f;--card:#222220;
--s1:#3987e5;--s2:#d95926;--s3:#199e70;--s4:#9085e9;--baseline:#8f8e86;--accent:#3987e5}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif}
main{max-width:860px;margin:0 auto;padding:32px 16px 64px}
h1{font-size:26px;margin:0 0 4px}h2{font-size:19px;margin:40px 0 8px;padding-top:8px;border-top:1px solid var(--grid)}
h3{font-size:15px;margin:20px 0 6px}
p,li{color:var(--fg2)} .muted{color:var(--muted)} strong{color:var(--fg)}
.sub{color:var(--muted);margin:0 0 20px}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px;margin:20px 0}
.tile{background:var(--card);border:1px solid var(--grid);border-radius:10px;padding:12px 14px}
.tile b{display:block;font-size:26px;color:var(--fg);font-variant-numeric:tabular-nums}
.tile span{font-size:13px;color:var(--fg2)}
figure{margin:16px 0;background:var(--card);border:1px solid var(--grid);border-radius:10px;padding:12px 12px 8px}
figcaption{font-weight:600;font-size:14px;margin:0 0 6px;color:var(--fg)}
svg{width:100%;height:auto;display:block;overflow:visible}
.grid{stroke:var(--grid);stroke-width:1}.axis{stroke:var(--axis);stroke-width:1}
.split{stroke:var(--axis);stroke-width:1;stroke-dasharray:2 3}
.tick{fill:var(--muted);font-size:11px}.lbl{fill:var(--fg2);font-size:12px}.val{fill:var(--fg2);font-size:11px;font-variant-numeric:tabular-nums}
.hit{fill:transparent}.hit:hover{fill:var(--fg2);fill-opacity:.25}
.legend{display:flex;flex-wrap:wrap;gap:6px 16px;font-size:12px;color:var(--fg2);margin-top:6px}
.key i{display:inline-block;width:16px;height:0;border-top-width:2px;margin-right:6px;vertical-align:middle}
.note{font-size:12px;color:var(--muted);margin:4px 0 0}
.scroll{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:13px;margin:8px 0;font-variant-numeric:tabular-nums}
th,td{text-align:left;padding:6px 8px;border-bottom:1px solid var(--grid)}th{color:var(--muted);font-weight:600}
td:not(:first-child):not(.muted){white-space:nowrap}
code{font-size:13px;background:var(--grid);padding:1px 4px;border-radius:4px}
pre{background:var(--card);border:1px solid var(--grid);border-radius:8px;padding:10px;overflow-x:auto;font-size:12px}
"""


def render(res: dict, path: Path) -> None:
    m = res["meta"]
    full_on = find(res, "full", "online")
    full_fr = find(res, "full", "warm20-frozen")
    full_wo = find(res, "full", "warm20-online")
    lookup = find(res, "desc lookup", "baseline")
    t_on = find(res, "time", "online")
    t_fr = find(res, "time", "warm20-frozen")
    t_wo = find(res, "time", "warm20-online")
    dh = find(res, "dow×hour majority", "baseline")
    maj = find(res, "majority", "baseline")
    S = lambda r: r["summary"]["tail"]  # noqa: E731

    # how many entries until online model's rolling top-1 first reaches 90% / 95%
    def first_reach(run, thr):
        return next((i for i, v in run["rolling"]["top1"] if v >= thr), None)

    r90, r95 = first_reach(full_on, 0.90), first_reach(full_on, 0.95)

    chart_full = line_chart(res, [
        {"label": "Online from zero", "run": full_on, "color": SERIES[0]},
        {"label": "Warm 20%, then online", "run": full_wo, "color": SERIES[2]},
        {"label": "Warm 20%, frozen", "run": full_fr, "color": SERIES[1]},
        {"label": "Exact-description lookup", "run": lookup, "color": BASE, "dashed": True},
    ], "top1", 0.8, 1.0, "With description: top-1 accuracy, rolling 500 entries")

    chart_time = line_chart(res, [
        {"label": "Online from zero", "run": t_on, "color": SERIES[0]},
        {"label": "Warm 20%, frozen", "run": t_fr, "color": SERIES[1]},
        {"label": "dow×hour majority", "run": dh, "color": BASE, "dashed": True},
    ], "top3", 0.0, 0.6, "Time only (hour, day of week, duration): top-3 accuracy, rolling 500 entries")

    time_bars = hbar_chart([
        ("VW time: top-3", S(t_on)["top3"], SERIES[0]),
        ("VW time: slot hit@3", S(t_on)["slot_hit3"], SERIES[0]),
        ("VW time: top-1", S(t_on)["top1"], SERIES[0]),
        ("dow×hour majority: top-3", S(dh)["top3"], BASE),
        ("dow×hour majority: top-1", S(dh)["top1"], BASE),
        ("Global majority: top-1", S(maj)["top1"], BASE),
        ("VW time: right root", S(t_on)["root"], SERIES[0]),
        ("Global majority: right root", S(maj)["root"], BASE),
    ], "Time-only vs baselines (last 80% of entries)", 0.8,
        "Slot hit@3: any top-3 guess matches any activity typed on the same line. Time features can't tell apart "
        "activities that share one time slot.")

    cold_bars = hbar_chart([
        ("VW full: exact", S(full_on)["cold_top1"], SERIES[0]),
        ("VW full: right root", S(full_on)["cold_root"], SERIES[0]),
        ("Lookup: exact", S(lookup)["cold_top1"], BASE),
        ("Lookup: right root", S(lookup)["cold_root"], BASE),
    ], f"Entries whose description was never seen before (n={S(full_on)['cold_n']} in the last 80%)", 1.0)

    def t(name):
        return find(res, name, "online")["summary"]["tail"]

    hier_rows = [("full", "Flat: name only, 0/1 cost"), ("full", "Ancestors, 0/1 cost (chosen)"),
                 ("full", "Ancestors + graded tree cost"), ("full", "Graded cost only")]
    names = {"Flat: name only, 0/1 cost": " (flat)", "Ancestors, 0/1 cost (chosen)": "",
             "Ancestors + graded tree cost": " (+graded cost)", "Graded cost only": " (graded cost only)"}
    hier_tbl = ["<table><thead><tr><th>Candidate encoding</th><th>Full top-1</th><th>Full top-3</th>"
                "<th>Full cold, right root</th><th>Time top-1</th><th>Time top-3</th><th>Time right root</th></tr></thead><tbody>"]
    for _, label in hier_rows:
        f, tt = t("full" + names[label]), t("time" + names[label])
        hier_tbl.append(f"<tr><td>{label}</td><td>{_pct(f['top1'])}</td><td>{_pct(f['top3'])}</td><td>{_pct(f['cold_root'])}</td>"
                        f"<td>{_pct(tt['top1'])}</td><td>{_pct(tt['top3'])}</td><td>{_pct(tt['root'])}</td></tr>")
    hier_tbl.append("</tbody></table>")

    main_tbl = summary_table(res, [
        ("VW full, online from zero", "full", "online"),
        ("VW full, warm 20% then online", "full", "warm20-online"),
        ("VW full, warm 20% frozen", "full", "warm20-frozen"),
        ("VW description only, online", "desc", "online"),
        ("Exact-description lookup", "desc lookup", "baseline"),
        ("VW time only, online", "time", "online"),
        ("VW time + #activities on line, online", "time+siblings", "online"),
        ("VW time only, warm 20% frozen", "time", "warm20-frozen"),
        ("dow×hour majority", "dow×hour majority", "baseline"),
        ("Global majority", "majority", "baseline"),
    ])

    page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Category Suggestion POC</title>
<style>{CSS}</style></head><body><main>
<h1>Suggesting time-entry categories with Vowpal Wabbit</h1>
<p class="sub">Replays {m['n_entries']:,} tracked entries ({m['first']} → {m['last']}, including {m['n_planned']:,} planned ones),
predicting each entry's category <em>before</em> learning from it. {m['n_categories_used']} of the {m['n_tree_nodes']} categories in the tree are used as labels.</p>

<div class="tiles">
<div class="tile"><b>{_pct(S(full_on)['top1'])}</b><span>top-1 with description, online model (last 80%)</span></div>
<div class="tile"><b>{_pct(S(lookup)['top1'])}</b><span>exact-description lookup, no ML</span></div>
<div class="tile"><b>{_pct(S(full_on)['cold_top1'], 0)}</b><span>top-1 on never-seen descriptions (lookup: {_pct(S(lookup)['cold_top1'], 0)})</span></div>
<div class="tile"><b>{_pct(S(t_on)['top3'], 0)}</b><span>top-3 from time of day, day of week and duration alone (49 classes)</span></div>
</div>

{daily_section(res)}
<h2>2. Accuracy as training data grows</h2>
<p>Each entry is scored <strong>before</strong> the model learns from it (progressive validation), in chronological order.
<strong>Online from zero</strong> starts empty. <strong>Warm 20%</strong> first trains on the first {m['split_index']:,} entries
(through {m['split_date']}, 3 shuffled passes), then either stops learning (<em>frozen</em>) or keeps learning.
All numbers below cover the same last 80% of entries.</p>
{chart_full}
<ul>
<li>The online model learns quickly. Its rolling accuracy first reaches 90% at entry {r90:,} and 95% at entry {r95:,}
({res['dates'][r95] if r95 is not None else 'n/a'}).</li>
<li><strong>Warm-starting doesn't help an online model.</strong> After the split, "warm 20% then online" and "online from zero"
are indistinguishable ({_pct(S(full_wo)['top1'])} vs {_pct(S(full_on)['top1'])}). Within a few hundred entries, the model from zero
has already caught up.</li>
<li><strong>A frozen model decays</strong> ({_pct(S(full_fr)['top1'])}) because new descriptions and new projects keep appearing.
You can see this as dips in the orange line. Keep learning online. It is cheap: the whole replay takes about 10s.</li>
<li>Time context adds almost nothing once a description exists: full {_pct(S(full_on)['top1'])} vs description only
{_pct(t('desc')['top1'])}. VW's gain over the lookup comes from <strong>generalising to new descriptions</strong>, through character n-grams
and the other activities on the same line.</li>
</ul>
{cold_bars}

<h2>3. Can it guess from time of day, day of week and duration?</h2>
<p>Partly. Time features alone do about twice as well as always guessing the most common category, but they are
nowhere near good enough to auto-fill. They are useful for ranking a <strong>short list</strong>, e.g. pre-sorting the category
picker or proposing categories for an empty gap on the calendar.</p>
{chart_time}
{time_bars}
<ul>
<li>Top-1 is {_pct(S(t_on)['top1'])} against {_pct(S(maj)['top1'])} for majority class. Top-3 is {_pct(S(t_on)['top3'])}.
In {_pct(S(t_on)['slot_hit3'], 0)} of entries, one of the top-3 guesses matches some activity typed in that time slot.</li>
<li>A frozen time model collapses ({_pct(S(t_fr)['top3'])} top-3). Routines change over the months, so time
patterns are not stationary. This is another argument for online learning.</li>
<li>Adding "number of activities on the line" helps: {_pct(t('time+siblings')['top1'])} top-1 and {_pct(t('time+siblings')['top3'])} top-3.</li>
</ul>
<h3>Which categories time alone can predict (last 80%, online)</h3>
<div class="scroll">{category_table(res, 'time', 12)}</div>

<h2>4. How the category hierarchy fits in</h2>
<p>The model is VW <code>--csoaa_ldf</code> with action-dependent features. Each entry becomes one multiline example: a
<em>shared</em> line with context features, and one line per candidate category. This keeps the label set open, so a category
added in GT just becomes another candidate line and needs no retraining. The hierarchy can enter in two places, which were tested
separately:</p>
<ul>
<li><strong>Ancestor features on candidate lines</strong> (<code>c=Citrus a0=Food a1=Fruit</code>): what the model learns about
<em>Citrus</em> also updates <em>Fruit</em> and <em>Food</em>. Rare children inherit a prior from their parent, and labels on internal nodes
(categories that have children but are also used directly as labels) are first-class candidates.</li>
<li><strong>Graded tree-distance costs</strong> (sibling 0.5, parent 0.25, other root 1.0) so near-misses are penalised less.</li>
</ul>
<div class="scroll">{''.join(hier_tbl)}</div>
<p><strong>Result:</strong> ancestor features cost nothing and help slightly. Exact accuracy is unchanged, and accuracy at the root
level on never-seen descriptions goes up a little (more for time-only). The effect is small here because most categories have plenty
of data. It should matter more for new or rare categories. Graded costs <em>hurt</em> ranking: top-3 for time drops by about 9 points, because the regression spreads score
across whole subtrees, so siblings crowd the top-3 list. They only buy a small gain in root accuracy. So the chosen design is
<strong>ancestor features + plain 0/1 costs</strong>. When a hierarchical answer is wanted ("probably something under this parent"), it
should come from <em>aggregating</em> candidate scores up the tree at prediction time, not from the training loss.</p>

<h3>Where the full model still gets it wrong</h3>
<p>Most remaining errors are genuinely ambiguous labels rather than model failures: the same description filed under siblings or a parent.</p>
<div class="scroll">{category_table(res, 'full', 10, worst=True)}</div>

<h2>5. All results (last 80% of entries)</h2>
<div class="scroll">{main_tbl}</div>
<p class="note">Right root: the top-1 guess lands under the correct one of the {len({p[0] for p in res['tree'].values()})} top-level categories.
Cold: entries whose description had not appeared earlier in the stream.</p>

<h2>6. Proposed design for integration</h2>
<ol>
<li><strong>Two suggestion modes, one model.</strong> While typing, use description + details + the other activities on the line + time.
This gives a confident top-1, so pre-select it. With no text (an empty calendar gap or a new line), use the same model with only time
features populated, and show a ranked top-3 instead of an auto-fill. A separate time-only VW model (trained flat) is cheap if the
shared one ranks worse with missing namespaces.</li>
<li><strong>Online always.</strong> Call <code>learn(entry)</code> each time an entry is saved, and especially when the user overrides a
suggestion. Never ship a frozen model.</li>
<li><strong>Hierarchy:</strong> candidates are generated from the current <code>TtRootCategory</code>, each with its ancestor features.
Adding a category needs no retrain, because it just becomes a new candidate. Renaming or moving categories, or re-tagging past entries
in bulk, does need a full retrain: features use category names, and an online model can't unlearn old labels. With the rebuild at
startup below, this is cheap. Show "Parent › Child" when leaf scores are split, by summing scores over each subtree.</li>
<li><strong>Rebuild from history instead of persisting.</strong> A full retrain takes a few seconds, so retrain from scratch whenever the time-tracking entries are loaded (at GT startup,
or lazily when the TimeTracker UI first opens, wherever entries are already parsed and mirrored into their collection). That means
no model file to save, version or invalidate. The same call also backs a "Retrain" action and runs automatically after
category-hierarchy edits or bulk re-tagging, debounced so a bulk edit triggers one retrain. Run it in the background and keep serving
the previous model, or no suggestions, until it finishes. A saved model file (~3 MB at <code>-b 20</code>) is optional, only if startup
time ever matters.</li>
<li><strong>Batch across the bridge, never per entry.</strong> The cost to avoid is crossing the GT↔Python bridge (or spawning a
sub-process or shell) thousands of times. Training must be one call for the whole history: either pass the Lepiter page path so
Python reads and parses it itself, which costs almost nothing to send, or send all entries as one serialized list. Reading the file
misses edits not yet saved to disk, so prefer sending the in-image collection if that matters. After that, per-entry
<code>predict_topk</code>/<code>learn</code> calls are fine (~0.5 ms of Python per call, so the bridge's own overhead dominates). Suggesting
a whole day page should also be one call returning all the page's suggestions. Planned API: <code>train_all(entries | path)</code>,
<code>suggest_many(entries, k)</code>, <code>learn(entry)</code>.</li>
<li><strong>GT bridge API today</strong> (<code>tt_suggest.model.Suggester</code>): <code>predict_topk(entry, k)</code>,
<code>scores(entry)</code>, <code>learn(entry)</code>, <code>save(path)</code>. These take <code>Entry</code> objects for now.
<code>Entry.as_dict</code> shows the plain-dict shape, mirroring <code>TtTrackedTime</code>, that the bridge should send.</li>
<li><strong>Known VW quirk:</strong> the Python bindings (9.11.9) segfault when predicting on unlabeled <code>csoaa_ldf</code> lines.
The workaround, already applied, is to send dummy costs at prediction time and read the per-candidate scores.</li>
</ol>
<p class="note">Generated by <code>uv run tt-suggest eval</code>. Hover over line points or bars for exact values.</p>
</main></body></html>"""
    path.write_text(page)
