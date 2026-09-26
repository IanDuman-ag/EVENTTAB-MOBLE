from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("events", "0009_judge_module_drafts_stages"),
    ]

    operations = [
        migrations.AddField(
            model_name="judgingevent",
            name="image_url",
            field=models.URLField(
                blank=True,
                default="",
                help_text="Cloudinary secure URL for the event image",
                max_length=500,
            ),
        ),
    ]
