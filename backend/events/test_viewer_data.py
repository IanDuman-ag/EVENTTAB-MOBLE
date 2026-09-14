from types import SimpleNamespace
from unittest.mock import Mock, patch

from django.test import SimpleTestCase

from .viewer_data import (
    _group_match_events,
    _judging_event_cards,
    fetch_viewer_rankings,
)


class ViewerCriteriaFilteringTests(SimpleTestCase):
    @patch("events.viewer_data._enrich_viewer_match", side_effect=lambda item: item)
    @patch("events.viewer_data._portal_judging_event_metadata")
    @patch("events.viewer_data.JudgingEvent.objects")
    def test_match_mirror_and_draft_are_not_criteria_cards(
        self,
        objects,
        portal_metadata,
        _enrich,
    ):
        category = SimpleNamespace(name="Events", category_type="socio_cultural")
        dance = SimpleNamespace(
            id=51,
            title="Modern Contemporary Dance",
            category=category,
            date=None,
            time=None,
            venue="Covered Court",
            status="active",
        )
        volleyball = SimpleNamespace(
            id=53,
            title="Men's Volleyball",
            category=SimpleNamespace(name="Sports", category_type="sports"),
            date=None,
            time=None,
            venue="Covered Court",
            status="completed",
        )
        draft = SimpleNamespace(
            id=54,
            title="Draft Pageant",
            category=category,
            date=None,
            time=None,
            venue="Hall",
            status="upcoming",
        )
        objects.select_related.return_value.all.return_value = [
            dance,
            volleyball,
            draft,
        ]
        portal_metadata.return_value = {
            51: {"scoring_method": "criteria", "publication_status": "published"},
            53: {"scoring_method": "match", "publication_status": "published"},
            54: {"scoring_method": "criteria", "publication_status": "draft"},
        }

        cards = _judging_event_cards()

        self.assertEqual([card["event_name"] for card in cards], ["Modern Contemporary Dance"])


class ViewerMatchGroupingTests(SimpleTestCase):
    def test_individual_games_are_one_card_per_parent_event(self):
        matches = [
            {
                "id": 181,
                "event_id": 71,
                "event_name": "Men's Volleyball",
                "sport": "sports",
                "status": "completed",
                "scheduled_time": "2026-08-24T08:00:00",
            },
            {
                "id": 182,
                "event_id": 71,
                "event_name": "Men's Volleyball",
                "sport": "sports",
                "status": "live",
                "scheduled_time": "2026-08-24T09:10:00",
            },
            {
                "id": 185,
                "event_id": 73,
                "event_name": "Men's Basketball",
                "sport": "sports",
                "status": "upcoming",
                "scheduled_time": "2026-08-25T08:00:00",
            },
        ]

        events = _group_match_events(matches)

        self.assertEqual(len(events), 2)
        volleyball = next(event for event in events if event["event_id"] == 71)
        self.assertEqual(volleyball["id"], 182)
        self.assertEqual(volleyball["status"], "live")
        self.assertEqual(volleyball["match_count"], 2)


class ViewerRankingMetadataTests(SimpleTestCase):
    @patch("events.viewer_data._build_team_rankings", return_value=[])
    @patch("events.viewer_data.fetch_combined_matches")
    def test_rankings_expose_real_sport_filters(self, combined_matches, _rankings):
        combined_matches.return_value = [
            {"sport": "volleyball"},
            {"sport": "basketball"},
            {"sport": "volleyball"},
        ]

        result = fetch_viewer_rankings()

        self.assertEqual(result["sports"], ["overall", "basketball", "volleyball"])
