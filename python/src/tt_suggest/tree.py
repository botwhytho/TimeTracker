"""Hierarchical category tree (mirrors TtRootCategory / TtCategory)."""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class CategoryTree:
    # name -> path from root, e.g. "Citrus" -> ("Food", "Fruit", "Citrus")
    paths: dict[str, tuple[str, ...]] = field(default_factory=dict)

    @classmethod
    def from_json(cls, root: dict) -> "CategoryTree":
        tree = cls()

        def walk(node: dict, prefix: tuple[str, ...]) -> None:
            for child in node.get("children", []):
                path = prefix + (child["name"],)
                if child["name"] in tree.paths:
                    raise ValueError(f"duplicate category name {child['name']!r}")
                tree.paths[child["name"]] = path
                walk(child, path)

        walk(root, ())
        return tree

    @property
    def names(self) -> list[str]:
        return list(self.paths)

    def path(self, name: str) -> tuple[str, ...]:
        return self.paths[name]

    def root(self, name: str) -> str:
        return self.paths[name][0]

    def distance(self, a: str, b: str) -> int:
        """Edges between two nodes, counting the (virtual) root as a node."""
        pa, pb = self.paths[a], self.paths[b]
        common = 0
        for x, y in zip(pa, pb):
            if x != y:
                break
            common += 1
        return (len(pa) - common) + (len(pb) - common)

    def cost(self, predicted: str, truth: str) -> float:
        """Normalised hierarchical cost in [0, 1]: 0 exact, 0.25 per edge inside
        the same root subtree (capped at 0.75), 1 for a different root."""
        if predicted == truth:
            return 0.0
        if self.root(predicted) != self.root(truth):
            return 1.0
        return min(0.75, 0.25 * self.distance(predicted, truth))
