# Generated manually — resilient to portal schema drift.

import django.db.models.deletion
from django.db import migrations, models


def _existing_columns(cursor, table):
    cursor.execute(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = %s
        """,
        [table],
    )
    return {row[0] for row in cursor.fetchall()}


def _table_exists(cursor, table):
    cursor.execute(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_name = %s
        """,
        [table],
    )
    return cursor.fetchone() is not None


def apply_schema(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        # Candidate.department may already exist on portal DB.
        cols = _existing_columns(cursor, "events_candidate")
        if "department" not in cols:
            cursor.execute(
                "ALTER TABLE events_candidate "
                "ADD COLUMN department varchar(200) DEFAULT '' NOT NULL"
            )

        # Criterion extras
        cols = _existing_columns(cursor, "events_criterion")
        alters = [
            ("comment_enabled", "ADD COLUMN comment_enabled boolean DEFAULT true NOT NULL"),
            ("comment_required", "ADD COLUMN comment_required boolean DEFAULT false NOT NULL"),
            ("decimal_places", "ADD COLUMN decimal_places smallint DEFAULT 1 NOT NULL"),
            (
                "low_score_comment_threshold",
                "ADD COLUMN low_score_comment_threshold numeric(5,1) NULL",
            ),
            ("min_score", "ADD COLUMN min_score numeric(5,1) DEFAULT 0 NOT NULL"),
            ("stage_id", "ADD COLUMN stage_id bigint NULL"),
        ]
        for name, sql in alters:
            if name not in cols:
                cursor.execute(f"ALTER TABLE events_criterion {sql}")

        # JudgingEvent extras
        cols = _existing_columns(cursor, "events_judgingevent")
        for name, sql in [
            ("faculty_in_charge", "ADD COLUMN faculty_in_charge varchar(200) DEFAULT '' NOT NULL"),
            ("instructions", "ADD COLUMN instructions text DEFAULT '' NOT NULL"),
        ]:
            if name not in cols:
                cursor.execute(f"ALTER TABLE events_judgingevent {sql}")

        # JudgeScore extras
        cols = _existing_columns(cursor, "events_judgescore")
        for name, sql in [
            ("comment", "ADD COLUMN comment text DEFAULT '' NOT NULL"),
            ("draft_step", "ADD COLUMN draft_step integer DEFAULT 0 NOT NULL"),
            ("is_draft", "ADD COLUMN is_draft boolean DEFAULT false NOT NULL"),
            ("previous_score", "ADD COLUMN previous_score numeric(5,1) NULL"),
            ("stage_id", "ADD COLUMN stage_id bigint NULL"),
        ]:
            if name not in cols:
                cursor.execute(f"ALTER TABLE events_judgescore {sql}")

        if not _table_exists(cursor, "events_judgingstage"):
            cursor.execute(
                """
                CREATE TABLE events_judgingstage (
                    id bigserial PRIMARY KEY,
                    name varchar(120) NOT NULL,
                    description text NOT NULL DEFAULT '',
                    weight_percent numeric(5,1) NOT NULL DEFAULT 100,
                    "order" integer NOT NULL DEFAULT 0,
                    status varchar(30) NOT NULL DEFAULT 'scoring_open',
                    qualifier_count integer NOT NULL DEFAULT 0,
                    scoring_deadline timestamptz NULL,
                    is_active boolean NOT NULL DEFAULT false,
                    event_id bigint NOT NULL REFERENCES events_judgingevent(id)
                        DEFERRABLE INITIALLY DEFERRED
                )
                """
            )

        if not _table_exists(cursor, "events_candidatestageeligibility"):
            cursor.execute(
                """
                CREATE TABLE events_candidatestageeligibility (
                    id bigserial PRIMARY KEY,
                    is_qualified boolean NOT NULL DEFAULT true,
                    stage_id bigint NOT NULL REFERENCES events_judgingstage(id)
                        DEFERRABLE INITIALLY DEFERRED,
                    candidate_id bigint NOT NULL REFERENCES events_candidate(id)
                        DEFERRABLE INITIALLY DEFERRED,
                    UNIQUE (stage_id, candidate_id)
                )
                """
            )


def noop_reverse(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ("events", "0008_team_logo_icon_url_length"),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AddField(
                    model_name="candidate",
                    name="department",
                    field=models.CharField(blank=True, default="", max_length=200),
                ),
                migrations.AddField(
                    model_name="criterion",
                    name="comment_enabled",
                    field=models.BooleanField(default=True),
                ),
                migrations.AddField(
                    model_name="criterion",
                    name="comment_required",
                    field=models.BooleanField(default=False),
                ),
                migrations.AddField(
                    model_name="criterion",
                    name="decimal_places",
                    field=models.PositiveSmallIntegerField(default=1),
                ),
                migrations.AddField(
                    model_name="criterion",
                    name="low_score_comment_threshold",
                    field=models.DecimalField(
                        blank=True,
                        decimal_places=1,
                        help_text="If set, comments become required when score is at or below this value",
                        max_digits=5,
                        null=True,
                    ),
                ),
                migrations.AddField(
                    model_name="criterion",
                    name="min_score",
                    field=models.DecimalField(decimal_places=1, default=0, max_digits=5),
                ),
                migrations.AddField(
                    model_name="judgescore",
                    name="comment",
                    field=models.TextField(blank=True, default=""),
                ),
                migrations.AddField(
                    model_name="judgescore",
                    name="draft_step",
                    field=models.PositiveIntegerField(
                        default=0, help_text="0-based criterion index for resume"
                    ),
                ),
                migrations.AddField(
                    model_name="judgescore",
                    name="is_draft",
                    field=models.BooleanField(default=False),
                ),
                migrations.AddField(
                    model_name="judgescore",
                    name="previous_score",
                    field=models.DecimalField(
                        blank=True, decimal_places=1, max_digits=5, null=True
                    ),
                ),
                migrations.AddField(
                    model_name="judgingevent",
                    name="faculty_in_charge",
                    field=models.CharField(blank=True, default="", max_length=200),
                ),
                migrations.AddField(
                    model_name="judgingevent",
                    name="instructions",
                    field=models.TextField(
                        blank=True,
                        help_text="Judge instructions shown on the event details screen",
                    ),
                ),
                migrations.CreateModel(
                    name="JudgingStage",
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
                        ("name", models.CharField(max_length=120)),
                        ("description", models.TextField(blank=True)),
                        (
                            "weight_percent",
                            models.DecimalField(decimal_places=1, default=100, max_digits=5),
                        ),
                        ("order", models.PositiveIntegerField(default=0)),
                        (
                            "status",
                            models.CharField(
                                choices=[
                                    ("upcoming", "Upcoming"),
                                    ("scoring_open", "Scoring Open"),
                                    ("waiting_judges", "Waiting for Other Judges"),
                                    ("waiting_faculty", "Waiting for Faculty Confirmation"),
                                    ("qualifiers_confirmed", "Qualified Contestants Confirmed"),
                                    ("next_stage_open", "Next Stage Open"),
                                    ("completed", "Final Stage Completed"),
                                ],
                                default="scoring_open",
                                max_length=30,
                            ),
                        ),
                        ("qualifier_count", models.PositiveIntegerField(default=0)),
                        ("scoring_deadline", models.DateTimeField(blank=True, null=True)),
                        ("is_active", models.BooleanField(default=False)),
                        (
                            "event",
                            models.ForeignKey(
                                on_delete=django.db.models.deletion.CASCADE,
                                related_name="stages",
                                to="events.judgingevent",
                            ),
                        ),
                    ],
                    options={"ordering": ["order", "id"]},
                ),
                migrations.AddField(
                    model_name="criterion",
                    name="stage",
                    field=models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="criteria",
                        to="events.judgingstage",
                    ),
                ),
                migrations.AddField(
                    model_name="judgescore",
                    name="stage",
                    field=models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="scores",
                        to="events.judgingstage",
                    ),
                ),
                migrations.CreateModel(
                    name="CandidateStageEligibility",
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
                        ("is_qualified", models.BooleanField(default=True)),
                        (
                            "candidate",
                            models.ForeignKey(
                                on_delete=django.db.models.deletion.CASCADE,
                                related_name="stage_eligibilities",
                                to="events.candidate",
                            ),
                        ),
                        (
                            "stage",
                            models.ForeignKey(
                                on_delete=django.db.models.deletion.CASCADE,
                                related_name="eligibilities",
                                to="events.judgingstage",
                            ),
                        ),
                    ],
                    options={"unique_together": {("stage", "candidate")}},
                ),
            ],
            database_operations=[
                migrations.RunPython(apply_schema, noop_reverse),
            ],
        ),
    ]
