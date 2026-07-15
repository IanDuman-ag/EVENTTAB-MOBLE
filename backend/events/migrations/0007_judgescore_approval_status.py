from django.db import migrations, models


APPROVAL_CHOICES = [
    ("pending", "Pending"),
    ("approved", "Approved"),
    ("rejected", "Rejected"),
]


def seed_pending(apps, schema_editor):
    JudgeScore = apps.get_model("events", "JudgeScore")
    JudgeScore.objects.filter(submitted_at__isnull=False).update(
        approval_status="pending"
    )


class Migration(migrations.Migration):
    dependencies = [
        ("events", "0006_fix_bracket_submission_approval_status"),
    ]

    operations = [
        migrations.AddField(
            model_name="judgescore",
            name="approval_status",
            field=models.CharField(
                choices=APPROVAL_CHOICES,
                default="pending",
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name="judgescore",
            name="reviewed_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="judgescore",
            name="review_note",
            field=models.CharField(blank=True, default="", max_length=255),
        ),
        migrations.RunPython(seed_pending, migrations.RunPython.noop),
    ]
