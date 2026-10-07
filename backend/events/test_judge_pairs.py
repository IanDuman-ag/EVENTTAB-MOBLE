from unittest import TestCase
from unittest.mock import patch

from .judge_data import _sync_portal_event_configuration


class JudgePairSyncTests(TestCase):
    @patch("events.judge_data.transaction.atomic")
    @patch("events.judge_data.JudgeScore.objects")
    @patch("events.judge_data.Candidate.objects")
    @patch("events.judge_data.connection.cursor")
    @patch("events.judge_data.JudgingEvent.objects")
    def test_selected_pairs_sync_as_competing_entries(
        self, events, cursor, candidates, scores, atomic
    ):
        db = cursor.return_value.__enter__.return_value
        db.fetchone.return_value = ("pair", "[14, 15]", "[]")
        db.fetchall.return_value = [
            (14, "First Pair", None, "Department A"),
            (15, "Second Pair", None, "Department B"),
            (16, "Unselected Pair", None, "Department C"),
        ]
        event = events.get.return_value
        event.candidates.all.return_value.order_by.return_value = []
        scores.filter.return_value.exists.return_value = False

        self.assertEqual(_sync_portal_event_configuration(64, 79), "pair")
        self.assertIn("entry.event_id = %s", db.execute.call_args.args[0])
        self.assertEqual(db.execute.call_args.args[1], [79])
        self.assertEqual(
            [call.kwargs["name"] for call in candidates.create.call_args_list],
            ["First Pair", "Second Pair"],
        )
