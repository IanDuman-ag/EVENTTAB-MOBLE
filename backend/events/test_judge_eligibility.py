from types import SimpleNamespace
from unittest import TestCase

from .judge_results import eligible_candidates


class PortalEligibilityTests(TestCase):
    def setUp(self):
        self.event = SimpleNamespace(id=1)
        self.candidates = [
            SimpleNamespace(id=101, number=1),
            SimpleNamespace(id=102, number=2),
        ]
        self.rules = {
            "portal_event_id": 77,
            "participant_ids": [6, 7],
            "results": {"qualified_participant_ids": {"0": []}},
        }

    def eligible(self, order):
        return eligible_candidates(
            self.event, {"order": order, "rules": self.rules}, self.candidates,
        )

    def test_opening_round_uses_roster_despite_empty_qualification_list(self):
        self.assertEqual(self.eligible(0), self.candidates)

    def test_opening_round_uses_roster_despite_stale_qualification_list(self):
        self.rules["results"]["qualified_participant_ids"]["0"] = [999]
        self.assertEqual(self.eligible(0), self.candidates)

    def test_later_round_keeps_qualification_filter(self):
        self.rules["results"]["qualified_participant_ids"]["1"] = [7]
        self.assertEqual(self.eligible(1), [self.candidates[1]])

    def test_later_round_with_no_qualifiers_stays_empty(self):
        self.rules["results"]["qualified_participant_ids"]["1"] = []
        self.assertEqual(self.eligible(1), [])

    def test_later_round_with_changed_roster_stays_blocked(self):
        self.rules["results"]["qualified_participant_ids"]["1"] = [7]
        self.rules["participant_ids"] = [6, 7, 8]
        self.assertEqual(self.eligible(1), [])
