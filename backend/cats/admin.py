from django.contrib import admin

from .models import Achievement, AchievementCat, Cat


class CatAdmin(admin.ModelAdmin):
    list_display = (
        'name',
        'color',
        'birth_year',
        'owner'
    )
    empty_value_display = '-пусто-'


class AchievementAdmin(admin.ModelAdmin):
    list_display = ('name',)
    empty_value_display = '-пусто-'


class AchievementCatAdmin(admin.ModelAdmin):
    list_display = (
        'cat',
        'achievement'
    )
    empty_value_display = '-пусто-'


admin.site.register(Achievement, AchievementAdmin)
admin.site.register(AchievementCat, AchievementCatAdmin)
admin.site.register(Cat, CatAdmin)
