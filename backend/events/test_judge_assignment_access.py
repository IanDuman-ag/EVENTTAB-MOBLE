from types import SimpleNamespace
from unittest import TestCase
from unittest.mock import patch

from rest_framework.test import APIRequestFactory, force_authenticate

from .judge_data import fetch_assignment_detail, portal_user_id, user_assigned_to_judging_event
from .judging_views import JudgingEventViewSet


class JudgeAssignmentAccessTests(TestCase):
    def setUp(self):
        self.user = SimpleNamespace(id=7, username="judge", is_staff=False, is_superuser=False, is_authenticated=True)

    def test_portal_identity_does_not_guess_another_accounts_id(self):
        with patch("events.judge_data.connection.cursor") as cursor:
            cursor.return_value.__enter__.return_value.fetchone.return_value = None
            self.assertIsNone(portal_user_id(self.user, fallback=False))

    def test_portal_assignment_is_authoritative_over_stale_mirror(self):
        for assigned in (True, False):
            with (
                self.subTest(assigned=assigned),
                patch("events.judge_data.portal_user_id", return_value=91),
                patch("events.judge_data.connection.cursor") as cursor,
                patch("events.judge_data.JudgingEvent.objects") as events,
            ):
                db = cursor.return_value.__enter__.return_value
                db.fetchall.return_value = [(assigned,)]
                self.assertEqual(user_assigned_to_judging_event(self.user, 42), assigned)
                self.assertEqual(db.execute.call_args.args[1], [91, 42])
                events.filter.assert_not_called()

    def test_unassigned_judge_cannot_open_detail_even_with_old_scores(self):
        with (
            patch("events.judge_data.user_assigned_to_judging_event", return_value=False),
            patch("events.judge_data.fetch_judge_assignments") as assignments,
            patch("events.judge_data.JudgeScore.objects") as scores,
        ):
            self.assertIsNone(fetch_assignment_detail(self.user, 42))
            assignments.assert_not_called()
            scores.filter.assert_not_called()

    def test_revoked_assignment_blocks_score_actions_before_validation(self):
        for action in ("save_draft", "submit_scores", "my_scores"):
            with (
                self.subTest(action=action),
                patch.object(JudgingEventViewSet, "get_object", return_value=SimpleNamespace(id=42)),
                patch("events.judging_views.user_assigned_to_judging_event", return_value=False),
            ):
                factory = APIRequestFactory()
                method = "get" if action == "my_scores" else "post"
                request = getattr(factory, method)("/", {}, format="json")
                force_authenticate(request, user=self.user)
                response = JudgingEventViewSet.as_view({method: action})(request, pk=42)
                self.assertEqual(response.status_code, 403)
