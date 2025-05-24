from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CustomTokenObtainPairView
from .views import register_user
from .views import (
    UserViewSet, OrganisationViewSet, RoleViewSet, UserOrganisationViewSet,
    CalendarViewSet, EventViewSet, ProjectViewSet, ChatViewSet, ChatUserViewSet,
    MessageViewSet, SongViewSet, TimetableViewSet, SetlistViewSet,
    HistoryViewSet, StatusViewSet, TaskViewSet, RecordingViewSet, UserProjectViewSet, ChatAccessViewSet, upgrade_to_premium, get_users_by_project
)
# Update api/urls.py to include JWT views
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenVerifyView,
)


# Add these imports at the top of your urls.py file
from .ical_views import (
    calendar_ical_feed, user_ical_feed,
    create_calendar_subscription, create_user_subscription,
    list_subscriptions, revoke_subscription
)

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'organisations', OrganisationViewSet)
router.register(r'roles', RoleViewSet)  # This is now a ReadOnlyModelViewSet
router.register(r'user-organisations', UserOrganisationViewSet)
router.register(r'calendars', CalendarViewSet)
router.register(r'events', EventViewSet)
router.register(r'projects', ProjectViewSet)
router.register(r'chats', ChatViewSet)
router.register(r'chat-users', ChatUserViewSet)
router.register(r'messages', MessageViewSet)
router.register(r'songs', SongViewSet)
router.register(r'timetables', TimetableViewSet)
router.register(r'setlists', SetlistViewSet)
router.register(r'history', HistoryViewSet)
router.register(r'statuses', StatusViewSet)  # This is now a ReadOnlyModelViewSet
router.register(r'tasks', TaskViewSet)
router.register(r'recordings', RecordingViewSet)
router.register(r'user-projects', UserProjectViewSet)
router.register(r'chat-access', ChatAccessViewSet)

# This line is crucial - make sure it exists at the bottom of the file
urlpatterns = router.urls

urlpatterns += [
    path('register/', register_user),  # ✅ korrekt für api_view
]

# Add these to urlpatterns
urlpatterns += [
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/verify/', TokenVerifyView.as_view(), name='token_verify'),
]

urlpatterns += [
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    # ... keep the other token endpoints the same
]

urlpatterns += [
    path('upgrade-to-premium/', upgrade_to_premium, name='upgrade_to_premium'),
]

# Add these to your urlpatterns list
urlpatterns += [
    # Public iCalendar feeds (accessible with token)
    path('ical/calendar/<str:token>/', calendar_ical_feed, name='calendar-ical'),
    path('ical/user/<str:token>/', user_ical_feed, name='user-ical'),
    
    # Authenticated endpoints to manage subscriptions
    path('subscriptions/calendar/<int:calendar_id>/', create_calendar_subscription, name='create-calendar-subscription'),
    path('subscriptions/user/', create_user_subscription, name='create-user-subscription'),
    path('subscriptions/', list_subscriptions, name='list-subscriptions'),
    path('subscriptions/<int:subscription_id>/revoke/', revoke_subscription, name='revoke-subscription'),
    path('projects/<int:project_id>/users/', get_users_by_project, name='project-users'),
]


