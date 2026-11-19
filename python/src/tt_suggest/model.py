"""Online category suggester backed by Vowpal Wabbit csoaa_ldf."""

from __future__ import annotations

import vowpalwabbit as vw

from tt_suggest.features import Encoder
from tt_suggest.load import Entry


class Suggester:
    def __init__(self, encoder: Encoder, extra_args: str = "", bits: int = 20) -> None:
        self.enc = encoder
        args = " ".join(["--csoaa_ldf m", f"-b {bits}", "--quiet", *encoder.interactions(), extra_args])
        self.ws = vw.Workspace(args)

    def scores(self, e: Entry) -> list[tuple[str, float]]:
        """(category, predicted cost) sorted best first."""
        exs = self.ws.parse(self.enc.example(e, None), vw.LabelType.COST_SENSITIVE)
        self.ws.predict(exs)
        costs = [x.get_partial_prediction() for x in exs[1:]]
        self.ws.finish_example(exs)
        return sorted(zip(self.enc.candidates, costs), key=lambda kv: kv[1])

    def predict_topk(self, e: Entry, k: int = 3) -> list[str]:
        return [c for c, _ in self.scores(e)[:k]]

    def learn(self, e: Entry) -> None:
        self.ws.learn(self.enc.example(e, e.category))

    def save(self, path: str) -> None:
        self.ws.save(path)
