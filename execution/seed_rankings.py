"""
execution/seed_rankings.py
---------------------------
Seeds EventCategory, JudgingEvent, Criterion, Candidate, and JudgeScore
data so the Rankings page has real data to display.

Usage:
    python execution/seed_rankings.py

Requirements:
    - Django backend is NOT required to be running (runs via Django shell directly)
    - venv must be active OR call as: .\\venv\\Scripts\\python.exe execution/seed_rankings.py
    - The database must already be migrated

Learnings:
    - Must set sys.path and DJANGO_SETTINGS_MODULE before importing Django models
"""

import os
import sys
import django
from decimal import Decimal

# ---------------------------------------------------------------------------
# Bootstrap Django
# ---------------------------------------------------------------------------
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'eventtab_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from events.models import EventCategory, JudgingEvent, Criterion, Candidate, JudgeScore

User = get_user_model()

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

CATEGORIES = [
    {'name': 'Academic', 'category_type': 'academic', 'icon': 'school', 'color': '#2196F3',
     'description': 'Academic competitions and quiz bees'},
    {'name': 'Sports', 'category_type': 'sports', 'icon': 'sports_basketball', 'color': '#FF7A18',
     'description': 'Athletic events and competitions'},
    {'name': 'Socio-Cultural', 'category_type': 'socio_cultural', 'icon': 'theater_comedy', 'color': '#9C27B0',
     'description': 'Cultural performances and arts'},
    {'name': 'E-Sports', 'category_type': 'esports', 'icon': 'sports_esports', 'color': '#00C5D9',
     'description': 'Electronic gaming competitions'},
]

EVENTS_BY_CATEGORY = {
    'Academic': [
        {'title': 'Quiz Bowl Championship', 'venue': 'Auditorium A', 'date': '2026-06-01', 'time': '09:00:00'},
        {'title': 'Science Olympiad', 'venue': 'Lab Complex', 'date': '2026-06-02', 'time': '10:00:00'},
        {'title': 'Math Invitational', 'venue': 'Hall B', 'date': '2026-06-03', 'time': '13:00:00'},
    ],
    'Sports': [
        {'title': 'Basketball Finals', 'venue': 'Main Gym', 'date': '2026-06-01', 'time': '14:00:00'},
        {'title': 'Volleyball Open', 'venue': 'Court 2', 'date': '2026-06-02', 'time': '08:00:00'},
        {'title': 'Swimming Competition', 'venue': 'Aquatic Center', 'date': '2026-06-03', 'time': '07:00:00'},
    ],
    'Socio-Cultural': [
        {'title': 'Dance Showdown', 'venue': 'Stage Hall', 'date': '2026-06-01', 'time': '18:00:00'},
        {'title': 'Singing Competition', 'venue': 'Music Hall', 'date': '2026-06-02', 'time': '17:00:00'},
        {'title': 'Pageant Night', 'venue': 'Main Auditorium', 'date': '2026-06-03', 'time': '19:00:00'},
    ],
    'E-Sports': [
        {'title': 'Mobile Legends Tournament', 'venue': 'Gaming Hub', 'date': '2026-06-01', 'time': '10:00:00'},
        {'title': 'Valorant Open', 'venue': 'Gaming Hub', 'date': '2026-06-02', 'time': '13:00:00'},
    ],
}

CRITERIA_BY_EVENT = {
    'Quiz Bowl Championship': [
        {'name': 'Accuracy', 'max_score': Decimal('50.0'), 'weight_percent': Decimal('50.0')},
        {'name': 'Speed', 'max_score': Decimal('30.0'), 'weight_percent': Decimal('30.0')},
        {'name': 'Difficulty Bonus', 'max_score': Decimal('20.0'), 'weight_percent': Decimal('20.0')},
    ],
    'Dance Showdown': [
        {'name': 'Choreography', 'max_score': Decimal('40.0'), 'weight_percent': Decimal('40.0')},
        {'name': 'Execution', 'max_score': Decimal('35.0'), 'weight_percent': Decimal('35.0')},
        {'name': 'Costume & Props', 'max_score': Decimal('25.0'), 'weight_percent': Decimal('25.0')},
    ],
    'Pageant Night': [
        {'name': 'Beauty', 'max_score': Decimal('30.0'), 'weight_percent': Decimal('30.0')},
        {'name': 'Intelligence', 'max_score': Decimal('40.0'), 'weight_percent': Decimal('40.0')},
        {'name': 'Poise & Personality', 'max_score': Decimal('30.0'), 'weight_percent': Decimal('30.0')},
    ],
}

CANDIDATES_BY_EVENT = {
    'Quiz Bowl Championship': ['Alice Reyes', 'Ben Santos', 'Clara Lim', 'Diego Cruz', 'Elena Park'],
    'Science Olympiad': ['Felix Tan', 'Grace Go', 'Henry Uy', 'Iris Sy', 'Jake Ong'],
    'Math Invitational': ['Kara Lee', 'Liam Ko', 'Mia Chan', 'Noah Chua', 'Olivia Bao'],
    'Basketball Finals': ['Team Alpha', 'Team Beta', 'Team Gamma', 'Team Delta'],
    'Volleyball Open': ['Team Red', 'Team Blue', 'Team Green', 'Team Gold'],
    'Swimming Competition': ['Mark Rivera', 'Nina Santos', 'Oscar Tan', 'Pia Cruz', 'Quinn Lim'],
    'Dance Showdown': ['Group Fiesta', 'Group Samba', 'Group Tango', 'Group Salsa', 'Group Waltz'],
    'Singing Competition': ['Rose Garcia', 'Sam Reyes', 'Tina Lee', 'Uma Park', 'Vince Ko'],
    'Pageant Night': ['Candidate 1', 'Candidate 2', 'Candidate 3', 'Candidate 4', 'Candidate 5'],
    'Mobile Legends Tournament': ['Team Valor', 'Team Storm', 'Team Blaze', 'Team Frost'],
    'Valorant Open': ['Team Phantom', 'Team Ghost', 'Team Cipher', 'Team Sage'],
}

# ---------------------------------------------------------------------------
# Seed helpers
# ---------------------------------------------------------------------------

def get_or_create_judge():
    """Return first available user as the seeding judge."""
    user = User.objects.filter(is_staff=False).first() or User.objects.first()
    if not user:
        print('  ! No users in DB. Run seed_test_user.py first.')
        sys.exit(1)
    return user


def seed_categories():
    print('\n[1/5] Seeding categories...')
    created = []
    for data in CATEGORIES:
        cat, made = EventCategory.objects.get_or_create(
            name=data['name'],
            defaults={
                'category_type': data['category_type'],
                'icon': data['icon'],
                'color': data['color'],
                'description': data['description'],
            }
        )
        status = 'created' if made else 'exists'
        print(f'  {status}: {cat.name}')
        created.append(cat)
    return {c.name: c for c in created + list(EventCategory.objects.all())}


def seed_events(categories):
    print('\n[2/5] Seeding judging events...')
    events = {}
    for cat_name, event_list in EVENTS_BY_CATEGORY.items():
        cat = categories.get(cat_name)
        if not cat:
            continue
        for e in event_list:
            ev, made = JudgingEvent.objects.get_or_create(
                title=e['title'],
                category=cat,
                defaults={
                    'date': e['date'],
                    'time': e['time'],
                    'venue': e['venue'],
                    'status': 'active',
                }
            )
            status = 'created' if made else 'exists'
            print(f'  {status}: {ev.title}')
            events[ev.title] = ev
    return events


def seed_criteria(events):
    print('\n[3/5] Seeding criteria...')
    for event_title, criteria_list in CRITERIA_BY_EVENT.items():
        ev = events.get(event_title)
        if not ev:
            continue
        for order, c in enumerate(criteria_list):
            cr, made = Criterion.objects.get_or_create(
                event=ev, name=c['name'],
                defaults={
                    'max_score': c['max_score'],
                    'weight_percent': c['weight_percent'],
                    'order': order,
                }
            )
            status = 'created' if made else 'exists'
            print(f'  {status}: [{ev.title}] {cr.name}')


def seed_candidates(events):
    print('\n[4/5] Seeding candidates...')
    for event_title, names in CANDIDATES_BY_EVENT.items():
        ev = events.get(event_title)
        if not ev:
            continue
        for i, name in enumerate(names, start=1):
            cand, made = Candidate.objects.get_or_create(
                event=ev, number=i,
                defaults={'name': name}
            )
            status = 'created' if made else 'exists'
            print(f'  {status}: [{ev.title}] #{i} {cand.name}')


def seed_scores(events, judge):
    print(f'\n[5/5] Seeding judge scores (judge={judge.username})...')
    import random
    random.seed(42)

    for event_title, criteria_list in CRITERIA_BY_EVENT.items():
        ev = events.get(event_title)
        if not ev:
            continue
        criteria = list(Criterion.objects.filter(event=ev))
        candidates = list(Candidate.objects.filter(event=ev))
        if not criteria or not candidates:
            continue

        for candidate in candidates:
            for criterion in criteria:
                score_val = round(random.uniform(float(criterion.max_score) * 0.6,
                                                  float(criterion.max_score)), 1)
                js, made = JudgeScore.objects.get_or_create(
                    judge=judge,
                    candidate=candidate,
                    criterion=criterion,
                    defaults={
                        'score': Decimal(str(score_val)),
                        'is_locked': True,
                    }
                )
                if made:
                    print(f'  scored: [{ev.title}] {candidate.name} / {criterion.name} = {js.score}')


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print('=== seed_rankings.py ===')
    judge = get_or_create_judge()
    categories = seed_categories()
    events = seed_events(categories)
    seed_criteria(events)
    seed_candidates(events)
    seed_scores(events, judge)
    print('\n[OK] Done. Rankings data is ready.')


if __name__ == '__main__':
    main()
