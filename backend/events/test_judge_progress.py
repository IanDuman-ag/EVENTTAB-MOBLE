from unittest import TestCase
from unittest.mock import Mock, patch

from .judge_data import _enrich_assignment_progress


class JudgeProgressTests(TestCase):
    def progress(self, statuses):
        with (
            patch("events.judge_data.JudgingEvent.objects") as events,
            patch("events.judge_data.judging_rounds") as stage,
            patch("events.judge_data.judge_round_progress") as progress,
        ):
            stage.return_value = ([{"id": "main", "name": "Main Scoring"}], {})
            progress.return_value = [{
                "round_id": "main", "name": "Main Scoring", "total": len(statuses),
                "scored": statuses.count("submitted"),
                "complete": bool(statuses) and all(status == "submitted" for status in statuses),
            }]
            events.get.return_value.faculty_in_charge = ""
            return _enrich_assignment_progress(
                Mock(), {"judging_event_id": 64, "status": "ongoing"}
            )

    def test_all_submitted_shows_done_and_full_progress(self):
        result = self.progress(["submitted", "submitted"])
        self.assertEqual(result["scoring_progress"], 100)
        self.assertTrue(result["scoring_complete"])
        self.assertEqual(result["event_status_label"], "Scores Submitted")
        self.assertEqual(result["action_label"], "View Submission")

    def test_drafts_returned_and_pending_are_unfinished(self):
        for unfinished in ["draft", "returned", "pending"]:
            with self.subTest(unfinished=unfinished):
                result = self.progress(["submitted", unfinished])
                self.assertEqual(result["scoring_progress"], 50)
                self.assertFalse(result["scoring_complete"])
                self.assertEqual(result["action_label"], "Continue Judging")

    def test_empty_event_is_not_done(self):
        result = self.progress([])
        self.assertEqual(result["scoring_progress"], 0)
        self.assertFalse(result["scoring_complete"])
