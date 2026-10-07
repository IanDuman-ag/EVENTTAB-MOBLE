from datetime import date, time
from decimal import Decimal
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIRequestFactory, force_authenticate

from .judge_data import _enrich_assignment_progress, fetch_score_history
from .judge_results import official_event_results, round_score
from .judging_views import JudgingEventViewSet
from .models import Candidate, CandidateStageEligibility, Criterion, EventCategory, JudgeScore, JudgingEvent, JudgingStage
from .tabulator_data import fetch_pending_queue, review_judge_scores
from .viewer_data import fetch_viewer_criteria_event_detail
from .views import JudgingEventViewSet as PublicStandingsViewSet


class FinalEventResultsTests(TestCase):
    def setUp(self):
        self.judges = [get_user_model().objects.create_user(username=f"judge{index}", email=f"judge{index}@example.test") for index in range(2)]
        category = EventCategory.objects.create(name="Pageant")
        self.event = JudgingEvent.objects.create(title="Pageant", category=category, date=date.today(), time=time(9), venue="Hall", status="active")
        self.event.assigned_judges.set(self.judges)
        self.candidates = [Candidate.objects.create(event=self.event, number=index + 1, name=f"Participant {index + 1}") for index in range(2)]
        self.criteria = [Criterion.objects.create(event=self.event, name=name, max_score=100, weight_percent=100) for name in ("Preliminary", "Final")]
        self.rounds = [
            {"id": "preliminary", "name": "Preliminary", "status": "completed", "weight_percent": 40, "criteria_ids": [self.criteria[0].id], "rules": {"results": {"final_result_basis": "weighted_rounds"}}},
            {"id": "final", "name": "Final", "status": "locked", "weight_percent": 60, "criteria_ids": [self.criteria[1].id], "rules": {"results": {"final_result_basis": "weighted_rounds"}}},
        ]
        # participant -> round -> judge scores
        self.values = [[[80, 100], [50, 70]], [[50, 70], [80, 100]]]

    def record(self, include_final=True, approval="approved"):
        for ci, candidate in enumerate(self.candidates):
            for ri, criterion in enumerate(self.criteria):
                if ri and not include_final:
                    continue
                for ji, judge in enumerate(self.judges):
                    JudgeScore.objects.update_or_create(judge=judge, candidate=candidate, criterion=criterion, defaults={
                        "score": self.values[ci][ri][ji], "is_locked": True,
                        "is_draft": False, "approval_status": approval, "submitted_at": timezone.now(),
                    })

    def results(self):
        return official_event_results(self.event, self.rounds, {})

    def test_approved_early_round_does_not_publish_standings_or_awards(self):
        self.record(include_final=False)
        with patch("events.judge_results.judging_rounds", return_value=(self.rounds, {})):
            for view in (PublicStandingsViewSet, JudgingEventViewSet):
                request = APIRequestFactory().get("/")
                force_authenticate(request, self.judges[0])
                response = view.as_view({"get": "standings"})(request, pk=self.event.id)
                self.assertEqual(response.data, [])
            detail = fetch_viewer_criteria_event_detail(self.event.id)
        self.assertEqual(detail["results"], [])
        self.assertEqual(detail["awards"], [])
        self.assertNotIn("Winner", [row["status"] for row in detail["contestants"]])

    def test_last_score_does_not_publish_before_round_closure_and_review(self):
        self.record()
        self.assertEqual(self.results(), [])
        self.rounds[-1]["status"] = "completed"
        final = JudgeScore.objects.filter(criterion=self.criteria[-1]).first()
        final.approval_status = "pending"
        final.save()
        self.assertEqual(self.results(), [])
        final.approval_status = "approved"
        final.is_draft = True
        final.save()
        self.assertEqual(self.results(), [])

    def test_weighted_final_uses_round_totals_and_judge_averages(self):
        self.record()
        self.rounds[-1]["status"] = "completed"
        results = self.results()
        self.assertEqual([row["total_score"] for row in results], [Decimal("78.00"), Decimal("72.00")])
        self.assertEqual(results[0]["candidate_id"], self.candidates[1].id)
        self.assertEqual(results[0]["rank"], 1)
        self.assertTrue(all(row["is_official"] for row in results))

    def test_final_only_and_cumulative_rules_are_not_interchangeable(self):
        self.record()
        self.rounds[-1]["status"] = "completed"
        self.rounds[-1]["rules"]["results"]["final_result_basis"] = "final_round_only"
        self.assertEqual([row["total_score"] for row in self.results()], [Decimal("90.00"), Decimal("60.00")])
        self.rounds[-1]["rules"]["results"]["final_result_basis"] = "cumulative_rounds"
        self.assertEqual([row["total_score"] for row in self.results()], [Decimal("150.00"), Decimal("150.00")])
        self.assertEqual([row["rank"] for row in self.results()], [1, 1])

    def test_missing_judge_or_participant_keeps_the_whole_result_provisional(self):
        self.record()
        self.rounds[-1]["status"] = "completed"
        JudgeScore.objects.filter(judge=self.judges[-1], candidate=self.candidates[-1], criterion=self.criteria[-1]).delete()
        self.assertEqual(self.results(), [])

    def test_final_qualification_excludes_eliminated_participants(self):
        self.record()
        stage = JudgingStage.objects.create(event=self.event, name="Final", status="completed")
        CandidateStageEligibility.objects.create(stage=stage, candidate=self.candidates[0], is_qualified=True)
        CandidateStageEligibility.objects.create(stage=stage, candidate=self.candidates[1], is_qualified=False)
        self.rounds[-1].update(status="completed", stage_id=stage.id)
        JudgeScore.objects.filter(candidate=self.candidates[1], criterion=self.criteria[-1]).delete()
        self.assertEqual([row["candidate_id"] for row in self.results()], [self.candidates[0].id])

    def test_round_calculation_applies_category_weights_raw_and_average_rules(self):
        self.record()
        scores = list(JudgeScore.objects.filter(judge=self.judges[0], candidate=self.candidates[0]).select_related("criterion"))
        metadata = {score.criterion_id: {"effective_weight_percent": 50} for score in scores}
        self.assertEqual(round_score(scores, {"rules": {"method": "weighted_percentage"}}, metadata), Decimal("65"))
        self.assertEqual(round_score(scores, {"rules": {"method": "raw_score"}}), Decimal("130"))
        self.assertEqual(round_score(scores, {"rules": {"method": "average_score"}}), Decimal("65"))

    def test_dashboard_distinguishes_round_completion_and_all_rounds_submitted(self):
        self.record(include_final=False)
        self.rounds[0]["is_active"] = True
        with patch("events.judge_data.judging_rounds", return_value=(self.rounds, {})):
            result = _enrich_assignment_progress(self.judges[0], {"judging_event_id": self.event.id, "status": "ongoing"})
        self.assertEqual(result["event_status_label"], "Round Submitted")
        self.assertFalse(result["scoring_complete"])
        self.assertEqual(result["rounds_completed"], 1)
        self.assertEqual(result["action_label"], "View Rounds")

    def test_history_keeps_round_scores_separate(self):
        self.record()
        with patch("events.judge_data.judging_rounds", return_value=(self.rounds, {})):
            history = fetch_score_history(self.judges[0])
        self.assertEqual(len(history["entries"]), 4)
        self.assertEqual({row["round_id"] for row in history["entries"]}, {"preliminary", "final"})
        self.assertTrue(all(not row["is_official"] for row in history["entries"]))

    def test_review_of_final_round_does_not_reject_approved_early_round(self):
        self.record()
        JudgeScore.objects.filter(criterion=self.criteria[-1]).update(approval_status="pending")
        with patch("events.tabulator_data.judging_rounds", return_value=(self.rounds, {})):
            review_judge_scores(self.judges[0].id, self.candidates[0].id, "rejected", round_id="final")
        self.assertEqual(JudgeScore.objects.get(judge=self.judges[0], candidate=self.candidates[0], criterion=self.criteria[0]).approval_status, "approved")

    def test_tabulator_queue_calculates_and_reviews_each_round_separately(self):
        self.record(approval="pending")
        with patch("events.tabulator_data.judging_rounds", return_value=(self.rounds, {})):
            queue = fetch_pending_queue()
        self.assertEqual(queue["counts"]["judge"], 8)
        self.assertEqual({item["round_id"] for item in queue["items"]}, {"preliminary", "final"})
        self.assertTrue(all(not item["is_official"] for item in queue["items"]))

    def test_deductions_are_applied_once_to_the_final_overall_score(self):
        self.record()
        self.rounds[-1]["status"] = "completed"
        self.rounds[-1]["rules"]["deductions"] = [
            {"deduction_type": "percentage", "value": 10},
            {"deduction_type": "fixed", "value": 5},
        ]
        self.assertEqual([row["total_score"] for row in self.results()], [Decimal("65.20"), Decimal("59.80")])

    def test_portal_main_round_respects_start_zero_and_carry_over(self):
        self.record()
        self.rounds[-1]["status"] = "completed"
        self.rounds[-1]["rules"] = {"portal_event_id": 77, "results": {"final_result_basis": "main_round"}}
        with patch("events.judge_results._required_judges", return_value={judge.id for judge in self.judges}):
            self.assertEqual([row["total_score"] for row in self.results()], [Decimal("90.00"), Decimal("60.00")])
            self.rounds[-1]["carry_previous_scores"] = True
            self.assertEqual([row["total_score"] for row in self.results()], [Decimal("150.00"), Decimal("150.00")])

    def test_manual_authorized_results_are_not_automatically_published(self):
        self.record()
        self.rounds[-1]["status"] = "completed"
        self.rounds[-1]["rules"]["results"]["final_result_basis"] = "manual_authorized"
        self.assertEqual(self.results(), [])

    def test_manual_tie_resolution_and_disabled_automation_are_honored(self):
        self.record()
        self.rounds[-1]["status"] = "completed"
        self.rounds[-1]["rules"]["results"]["auto_calculate_final"] = False
        self.assertEqual(self.results(), [])
        self.rounds[-1]["rules"]["results"]["auto_calculate_final"] = True
        self.rounds[-1]["rules"]["results"].update(final_result_basis="cumulative_rounds", stage_tiebreak_method="manual_decision")
        self.assertEqual(self.results(), [])

    def test_single_round_keeps_verified_results_available(self):
        self.record(include_final=False)
        results = official_event_results(self.event, self.rounds[:1], {})
        self.assertEqual([row["total_score"] for row in results], [Decimal("90.00"), Decimal("60.00")])
