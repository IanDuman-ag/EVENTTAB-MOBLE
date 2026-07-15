from django.db import models
from django.utils import timezone
from django.conf import settings


class Team(models.Model):
    """Represents a team participating in events"""
    name = models.CharField(max_length=100)
    abbreviation = models.CharField(max_length=10)
    logo_icon = models.CharField(
        max_length=500,
        blank=True,
        help_text="Emoji, short code, or image URL for the team logo",
    )
    color = models.CharField(max_length=7, default="#00C5D9",
        help_text="Hex color code, e.g. #FF0000")
    description = models.TextField(blank=True,
        help_text="Short team bio shown on the Team Details page")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    class Meta:
        ordering = ['name']


class Match(models.Model):
    """Represents a sports match/game"""
    STATUS_CHOICES = [
        ('upcoming',  'Upcoming'),
        ('live',      'Live'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    SPORT_CHOICES = [
        ('basketball', 'Basketball'),
        ('volleyball', 'Volleyball'),
        ('football',   'Football'),
        ('other',      'Other'),
    ]

    ROUND_CHOICES = [
        ('group_stage',   'Group Stage'),
        ('quarterfinal',  'Quarterfinal'),
        ('semifinal',     'Semifinal'),
        ('final',         'Final'),
        ('other',         'Other'),
    ]

    title         = models.CharField(max_length=200)
    sport         = models.CharField(max_length=50, choices=SPORT_CHOICES, default='basketball')
    round_label   = models.CharField(max_length=30, choices=ROUND_CHOICES, default='group_stage',
                        help_text="Stage of the competition shown as a badge")
    team_a        = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='matches_as_team_a')
    team_b        = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='matches_as_team_b')
    score_a       = models.IntegerField(null=True, blank=True)
    score_b       = models.IntegerField(null=True, blank=True)
    scheduled_time = models.DateTimeField()
    status        = models.CharField(max_length=20, choices=STATUS_CHOICES, default='upcoming')
    is_featured   = models.BooleanField(default=False,
                        help_text="Show this match in the 'UP NEXT' featured slot")
    venue         = models.CharField(max_length=200, blank=True)
    venue_full    = models.CharField(max_length=300, blank=True,
                        help_text="Full venue address, e.g. 'USTP Oroquieta Campus'")
    notes         = models.TextField(blank=True,
                        help_text="Shown in Match Details → Notes row")
    updated_at    = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.title}: {self.team_a.abbreviation} vs {self.team_b.abbreviation}"

    @property
    def winner(self):
        if self.status == 'completed' and self.score_a is not None and self.score_b is not None:
            if self.score_a > self.score_b:
                return self.team_a
            elif self.score_b > self.score_a:
                return self.team_b
        return None

    class Meta:
        ordering = ['scheduled_time']
        verbose_name_plural = 'Matches'


class Activity(models.Model):
    """Represents activity feed items"""
    ACTIVITY_TYPES = [
        ('match_result', 'Match Result'),
        ('match_scheduled', 'Match Scheduled'),
        ('team_update', 'Team Update'),
        ('announcement', 'Announcement'),
    ]
    
    activity_type = models.CharField(max_length=50, choices=ACTIVITY_TYPES, default='match_result')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    match = models.ForeignKey(Match, on_delete=models.CASCADE, null=True, blank=True, related_name='activities')
    icon = models.CharField(max_length=50, default='emoji_events', help_text="Material icon name")
    created_at = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        return self.title
    
    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = 'Activities'


class EventCategory(models.Model):
    CATEGORY_CHOICES = [
        ('academic', 'Academic Event'),
        ('esports', 'Esports Event'),
        ('sports', 'Sports Event'),
        ('socio_cultural', 'Socio Cultural'),
    ]
    name = models.CharField(max_length=100)
    category_type = models.CharField(max_length=30, choices=CATEGORY_CHOICES, default='academic')
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=50, default='school', help_text="Material icon name")
    color = models.CharField(max_length=7, default='#2196F3')

    def __str__(self):
        return self.name

    class Meta:
        verbose_name_plural = 'Event Categories'


class JudgingEvent(models.Model):
    STATUS_CHOICES = [
        ('upcoming', 'Upcoming'),
        ('active', 'Active'),
        ('completed', 'Completed'),
    ]
    title = models.CharField(max_length=200)
    category = models.ForeignKey(EventCategory, on_delete=models.CASCADE, related_name='events')
    date = models.DateField()
    time = models.TimeField()
    venue = models.CharField(max_length=200)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='upcoming')
    description = models.TextField(blank=True)
    assigned_judges = models.ManyToManyField(settings.AUTH_USER_MODEL, blank=True, related_name='assigned_events')

    def __str__(self):
        return self.title

    class Meta:
        ordering = ['date', 'time']


class Criterion(models.Model):
    event = models.ForeignKey(JudgingEvent, on_delete=models.CASCADE, related_name='criteria')
    name = models.CharField(max_length=100)
    description = models.CharField(max_length=200, blank=True)
    max_score = models.DecimalField(max_digits=5, decimal_places=1)
    weight_percent = models.DecimalField(max_digits=5, decimal_places=1, help_text="Weight as percentage e.g. 20.0")
    order = models.PositiveIntegerField(default=0)

    def __str__(self):
        return f"{self.event.title} - {self.name}"

    class Meta:
        ordering = ['order']


class Candidate(models.Model):
    event = models.ForeignKey(JudgingEvent, on_delete=models.CASCADE, related_name='candidates')
    name = models.CharField(max_length=200)
    number = models.PositiveIntegerField(help_text="Candidate number e.g. 1")
    photo = models.ImageField(upload_to='candidates/', null=True, blank=True)
    description = models.TextField(blank=True)

    def __str__(self):
        return f"#{self.number} {self.name}"

    class Meta:
        ordering = ['number']
        unique_together = ['event', 'number']


class JudgeScore(models.Model):
    APPROVAL_CHOICES = [
        ("pending", "Pending"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
    ]

    judge = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='scores')
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE, related_name='scores')
    criterion = models.ForeignKey(Criterion, on_delete=models.CASCADE, related_name='scores')
    score = models.DecimalField(max_digits=5, decimal_places=1)
    is_locked = models.BooleanField(default=False)
    submitted_at = models.DateTimeField(null=True, blank=True)
    verification_id = models.CharField(max_length=50, blank=True)
    approval_status = models.CharField(
        max_length=20,
        choices=APPROVAL_CHOICES,
        default="pending",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    review_note = models.CharField(max_length=255, blank=True, default="")

    def __str__(self):
        return f"{self.judge.username} - {self.candidate.name} - {self.criterion.name}: {self.score}"

    class Meta:
        unique_together = ['judge', 'candidate', 'criterion']


class ScorerSubmission(models.Model):
    """Score results submitted by a scorer — pending until admin approves."""

    APPROVAL_CHOICES = [
        ("pending", "Pending"),
        ("approved", "Approved"),
    ]

    match = models.ForeignKey(
        Match,
        on_delete=models.CASCADE,
        related_name="scorer_submissions",
    )
    scorer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="scorer_submissions",
    )
    score_a = models.IntegerField()
    score_b = models.IntegerField()
    match_status = models.CharField(max_length=20, default="live")
    approval_status = models.CharField(
        max_length=20,
        choices=APPROVAL_CHOICES,
        default="pending",
    )
    submitted_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return (
            f"{self.scorer.username} — {self.match.title} "
            f"({self.approval_status})"
        )

    class Meta:
        ordering = ["-submitted_at"]
        unique_together = ["match", "scorer"]


class BracketScorerSubmission(models.Model):
    """Bracket match scores submitted by a scorer."""

    APPROVAL_CHOICES = [
        ("pending", "Pending"),
        ("approved", "Approved"),
        ("returned", "Returned"),
    ]

    bracket_match_id = models.IntegerField()
    event_id = models.IntegerField(null=True, blank=True)
    scorer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="bracket_scorer_submissions",
    )
    score_a = models.IntegerField()
    score_b = models.IntegerField()
    match_status = models.CharField(max_length=20, default="live")
    approval_status = models.CharField(
        max_length=20,
        choices=APPROVAL_CHOICES,
        default="pending",
    )
    submitted_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-submitted_at"]
        unique_together = ["bracket_match_id", "scorer"]
