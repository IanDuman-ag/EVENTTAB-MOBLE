from datetime import datetime
from types import SimpleNamespace
from unittest import TestCase
from unittest.mock import Mock, patch

from .judge_data import fetch_assignment_detail


class JudgeCriteriaPreviewTests(TestCase):
    def test_preview_includes_every_round_without_expanding_scoring_criteria(self):
        rows = [
            SimpleNamespace(
                id=index, name=f"Criterion {index}", description="",
                max_score=100, min_score=0, weight_percent=10, order=index,
                stage_id=1 if index < 7 else 2, comment_enabled=True,
                comment_required=False, low_score_comment_threshold=None,
                decimal_places=1,
            )
            for index in range(1, 9)
        ]
        user = SimpleNamespace(date_joined=datetime(2026, 1, 1))
        event = SimpleNamespace(instructions="", description="", faculty_in_charge="", status="active")
        with (
            patch("events.judge_data.user_assigned_to_judging_event", return_value=True),
            patch("events.judge_data.fetch_judge_assignments", return_value=[{
                "judging_event_id": 42, "assignment_type": "CRITERIA BASED",
                "status": "ongoing", "criteria": [],
            }]),
            patch("events.judge_data.JudgingEvent.objects") as events,
            patch("events.judge_data.Candidate.objects") as candidates,
            patch("events.judge_results.CandidateStageEligibility.objects") as eligibility,
            patch("events.judge_data.Criterion.objects") as criteria,
            patch("events.judge_data._criteria_for_judging_event", return_value=[]),
            patch("events.judge_data.judging_rounds", return_value=([
                {"id": "1", "stage_id": 1, "name": "Talent", "status": "scoring_open", "is_active": True, "criteria_ids": list(range(1, 7))},
                {"id": "2", "stage_id": 2, "name": "Final", "status": "locked", "criteria_ids": [7, 8]},
            ], {})),
            patch("events.judge_data.portal_user_id", return_value=1),
        ):
            events.get.return_value = event
            candidates.filter.return_value.order_by.return_value = []
            eligibility.filter.return_value.values_list.return_value = []
            queryset = Mock()
            queryset.exists.return_value = True
            queryset.__iter__ = Mock(side_effect=lambda: iter(rows))
            criteria.filter.return_value.order_by.return_value = queryset
            result = fetch_assignment_detail(user, 42)
            final = fetch_assignment_detail(user, 42, round_id="2")

        self.assertEqual(len(result["all_criteria"]), 8)
        self.assertEqual(len(result["criteria"]), 6)
        self.assertEqual(result["all_criteria"][-1]["stage_id"], 2)
        self.assertEqual(result["current_stage"]["name"], "Talent")
        self.assertEqual(final["current_round"], "Final")
        self.assertEqual([c["id"] for c in final["criteria"]], [7, 8])
        self.assertFalse(final["can_score"])
