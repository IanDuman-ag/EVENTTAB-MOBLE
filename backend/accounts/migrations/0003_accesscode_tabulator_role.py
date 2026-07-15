from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0002_accesscode"),
    ]

    operations = [
        migrations.AlterField(
            model_name="accesscode",
            name="role",
            field=models.CharField(
                choices=[
                    ("judge", "Judge"),
                    ("scorer", "Scorer"),
                    ("tabulator", "Tabulator"),
                ],
                max_length=20,
            ),
        ),
    ]
