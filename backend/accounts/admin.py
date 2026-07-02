from django.contrib import admin

from .models import AccessCode


@admin.register(AccessCode)
class AccessCodeAdmin(admin.ModelAdmin):
    list_display = ("code", "role", "label", "is_active", "created_at")
    list_filter = ("role", "is_active")
    search_fields = ("code", "label", "user__username")
    readonly_fields = ("code", "user", "created_at")

    fieldsets = (
        (None, {"fields": ("role", "label", "is_active")}),
        (
            "Generated",
            {
                "fields": ("code", "user", "created_at"),
                "description": "The access code and linked account are created automatically on save.",
            },
        ),
    )
