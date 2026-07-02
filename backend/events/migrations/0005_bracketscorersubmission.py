from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("events", "0004_scorersubmission"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="BracketScorerSubmission",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("bracket_match_id", models.IntegerField()),
                ("event_id", models.IntegerField(blank=True, null=True)),
                ("score_a", models.IntegerField()),
                ("score_b", models.IntegerField()),
                ("match_status", models.CharField(default="live", max_length=20)),
                (
                    "approval_status",
                    models.CharField(
                        choices=[
                            ("pending", "Pending"),
                            ("approved", "Approved"),
                            ("returned", "Returned"),
                        ],
                        default="pending",
                        max_length=20,
                    ),
                ),
                ("submitted_at", models.DateTimeField(auto_now=True)),
                (
                    "scorer",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="bracket_scorer_submissions",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "ordering": ["-submitted_at"],
                "unique_together": {("bracket_match_id", "scorer")},
            },
        ),
    ]
