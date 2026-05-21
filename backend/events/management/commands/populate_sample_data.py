from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from events.models import Team, Match, Activity


class Command(BaseCommand):
    help = 'Populate database with sample teams, matches, and activities'

    def handle(self, *args, **options):
        self.stdout.write('Creating sample data...')
        
        # Create Teams
        teams_data = [
            {'name': 'BSIT', 'abbreviation': 'BSIT', 'logo_icon': 'A', 'color': '#00C5D9'},
            {'name': 'BFPT', 'abbreviation': 'BFPT', 'logo_icon': '🛡️', 'color': '#7DEEFF'},
            {'name': 'BTLED', 'abbreviation': 'BTLED', 'logo_icon': 'A', 'color': '#00C5D9'},
            {'name': 'BSCS', 'abbreviation': 'BSCS', 'logo_icon': '⚔️', 'color': '#9FA1A5'},
        ]
        
        teams = {}
        for team_data in teams_data:
            team, created = Team.objects.get_or_create(
                abbreviation=team_data['abbreviation'],
                defaults=team_data
            )
            teams[team.abbreviation] = team
            if created:
                self.stdout.write(f'  Created team: {team.name}')
        
        # Create Featured Match (completed)
        featured_match, created = Match.objects.get_or_create(
            title='BASKETBALL MENS FINALS',
            team_a=teams['BSIT'],
            team_b=teams['BFPT'],
            defaults={
                'sport': 'basketball',
                'score_a': 124,
                'score_b': 118,
                'scheduled_time': timezone.now() - timedelta(hours=5),
                'status': 'completed',
                'is_featured': True,
                'venue': 'Main Arena',
            }
        )
        if created:
            self.stdout.write(f'  Created featured match: {featured_match.title}')
        
        # Create Upcoming Matches
        upcoming_matches_data = [
            {
                'title': 'BTLED (MEN) vs BSIT (MEN)',
                'team_a': teams['BTLED'],
                'team_b': teams['BSIT'],
                'scheduled_time': timezone.now() + timedelta(days=1, hours=19),
                'sport': 'basketball',
            },
            {
                'title': 'BFPT vs BSCS',
                'team_a': teams['BFPT'],
                'team_b': teams['BSCS'],
                'scheduled_time': timezone.now() + timedelta(days=2, hours=21),
                'sport': 'basketball',
            },
        ]
        
        for match_data in upcoming_matches_data:
            match, created = Match.objects.get_or_create(
                title=match_data['title'],
                defaults={
                    **match_data,
                    'status': 'upcoming',
                    'is_featured': False,
                }
            )
            if created:
                self.stdout.write(f'  Created upcoming match: {match.title}')
        
        # Create Activity Feed
        activity, created = Activity.objects.get_or_create(
            title='BSIT won their match against BFPT',
            defaults={
                'activity_type': 'match_result',
                'description': 'Final score: BSIT 124 - BFPT 118',
                'match': featured_match,
                'icon': 'emoji_events',
                'created_at': timezone.now() - timedelta(hours=5),
            }
        )
        if created:
            self.stdout.write(f'  Created activity: {activity.title}')
        
        self.stdout.write(self.style.SUCCESS('Sample data created successfully!'))
