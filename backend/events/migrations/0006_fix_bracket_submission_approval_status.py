from django.db import migrations


def reset_auto_approved_submissions(apps, schema_editor):
    """Completed match status was incorrectly treated as tabulator approval."""
    BracketScorerSubmission = apps.get_model("events", "BracketScorerSubmission")
    BracketScorerSubmission.objects.filter(
        approval_status="approved",
        match_status="completed",
    ).update(approval_status="pending")


class Migration(migrations.Migration):

    dependencies = [
        ("events", "0005_bracketscorersubmission"),
    ]

    operations = [
        migrations.RunPython(
            reset_auto_approved_submissions,
            migrations.RunPython.noop,
        ),
    ]
