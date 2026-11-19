from tt_suggest.tree import CategoryTree

# Synthetic tree; deliberately unrelated to any real category set.
ROOT = {"children": [
    {"name": "Food", "children": [
        {"name": "Fruit", "children": [{"name": "Citrus", "children": []},
                                       {"name": "Berry", "children": []}]}]},
    {"name": "Tools", "children": [{"name": "Hammer", "children": []}]},
]}


def test_paths_and_distance():
    t = CategoryTree.from_json(ROOT)
    assert t.path("Citrus") == ("Food", "Fruit", "Citrus")
    assert t.distance("Citrus", "Fruit") == 1
    assert t.distance("Citrus", "Berry") == 2
    assert t.distance("Citrus", "Hammer") == 5
    assert t.cost("Citrus", "Citrus") == 0
    assert t.cost("Citrus", "Fruit") == 0.25
    assert t.cost("Citrus", "Hammer") == 1.0
