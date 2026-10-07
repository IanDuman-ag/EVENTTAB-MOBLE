from datetime import date, time
from types import SimpleNamespace
from unittest import TestCase as UnitTestCase
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.exceptions import ValidationError
from rest_framework.test import APIRequestFactory, force_authenticate

from .judge_rounds import judging_rounds, select_judging_round
from .judging_views import JudgingEventViewSet
from .models import Candidate, Criterion, EventCategory, JudgeScore, JudgingEvent


class PortalRoundTests(UnitTestCase):
    def test_portal_rounds_map_to_existing_ids_and_keep_full_metadata(self):
        criteria = [SimpleNamespace(id=71, name="Confidence"), SimpleNamespace(id=72, name="Impact")]
        portal = ([
            {"id": "preliminary", "name": "Preliminary", "status": "open"},
            {"id": "final", "name": "Final", "status": "locked"},
        ], [
            {"name": "Confidence", "round_id": "preliminary", "subcriteria": [{"name": "Poise", "max_score": 20}]},
            {"name": "Impact", "round_id": "final"},
        ])
        with (
            patch("events.judge_rounds.Criterion.objects") as manager,
            patch("events.judge_rounds.connection.cursor") as cursor,
        ):
            manager.filter.return_value.order_by.return_value = criteria
            cursor.return_value.__enter__.return_value.fetchone.return_value = portal
            rounds, metadata = judging_rounds(SimpleNamespace(id=42))
        self.assertEqual(rounds[0]["criteria_ids"], [71])
        self.assertEqual(rounds[1]["criteria_ids"], [72])
        self.assertEqual(metadata[71]["subcriteria"][0]["name"], "Poise")
        self.assertEqual(select_judging_round(rounds, "final")["name"], "Final")
        with self.assertRaises(ValidationError):
            select_judging_round(rounds, "another-event-round")


class RoundScoringTests(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(username="round_judge", email="round@example.test")
        category = EventCategory.objects.create(name="Pageant")
        self.event = JudgingEvent.objects.create(title="Pageant", category=category, date=date.today(), time=time(9), venue="Hall", status="active")
        self.candidate = Candidate.objects.create(event=self.event, number=1, name="Contestant")
        self.first = Criterion.objects.create(event=self.event, name="Confidence", max_score=100, weight_percent=100)
        self.final = Criterion.objects.create(event=self.event, name="Impact", max_score=100, weight_percent=100)
        self.rounds = [
            {"id": "preliminary", "stage_id": None, "status": "open", "criteria_ids": [self.first.id], "is_active": True},
            {"id": "final", "stage_id": None, "status": "open", "criteria_ids": [self.final.id]},
        ]

    def request(self, action, round_id, scores=None):
        factory = APIRequestFactory()
        method = "get" if action == "my_scores" else "post"
        body = {"candidate_id": self.candidate.id, "round_id": round_id}
        if scores is not None:
            body["scores"] = scores
        request = getattr(factory, method)("/", body, format="json")
        force_authenticate(request, self.user)
        with (
            patch("events.judging_views.user_assigned_to_judging_event", return_value=True),
            patch("events.judging_views.judging_rounds", return_value=(self.rounds, {})),
        ):
            return JudgingEventViewSet.as_view({method: action})(request, pk=self.event.id)

    def test_submitting_first_round_does_not_block_second_round(self):
        for round_id, criterion in (("preliminary", self.first), ("final", self.final)):
            response = self.request("submit_scores", round_id, [{"criterion_id": criterion.id, "score": 80}])
            self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(JudgeScore.objects.count(), 2)
        for round_id, criterion in (("preliminary", self.first), ("final", self.final)):
            response = self.request("my_scores", round_id)
            self.assertEqual([row["criterion"] for row in response.data], [criterion.id])

    def test_wrong_round_criteria_and_locked_rounds_cannot_write(self):
        for action in ("save_draft", "submit_scores"):
            response = self.request(action, "preliminary", [{"criterion_id": self.final.id, "score": 80}])
            self.assertEqual(response.status_code, 400)
        self.rounds[1]["status"] = "locked"
        for action in ("save_draft", "submit_scores"):
            response = self.request(action, "final", [{"criterion_id": self.final.id, "score": 80}])
            self.assertEqual(response.status_code, 400)
        self.assertFalse(JudgeScore.objects.exists())

    def test_approved_first_round_does_not_block_final_draft(self):
        JudgeScore.objects.create(judge=self.user, candidate=self.candidate, criterion=self.first, score=90, is_locked=True, approval_status="approved")
        response = self.request("save_draft", "final", [{"criterion_id": self.final.id, "score": 75}])
        self.assertEqual(response.status_code, 200, response.data)
        self.assertTrue(JudgeScore.objects.get(criterion=self.final).is_draft)

    def test_upcoming_event_cannot_be_scored(self):
        self.event.status = "upcoming"
        self.event.save(update_fields=["status"])
        response = self.request("submit_scores", "preliminary", [{"criterion_id": self.first.id, "score": 80}])
        self.assertEqual(response.status_code, 400)
        self.assertFalse(JudgeScore.objects.exists())
