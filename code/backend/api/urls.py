from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CustomTokenObtainPairView
from .views import register_user
from .views import (
    UserViewSet, OrganisationViewSet, RoleViewSet, UserOrganisationViewSet,
    CalendarViewSet, EventViewSet, ProjectViewSet, ChatViewSet, ChatUserViewSet,
    MessageViewSet, SongViewSet, TimetableViewSet, SetlistViewSet,
    HistoryViewSet, StatusViewSet, TaskViewSet, RecordingViewSet, ExternalViewSet, 
    ChatAccessViewSet, upgrade_to_premium, get_users_by_project, get_externals_by_project, get_externals_by_organisation, 
    remove_user_from_organisation, get_all_users_by_organisation,
    OrganisationInvitationViewSet, get_invitation_details,
    accept_invitation, decline_invitation, my_invitations, my_profile, BugReportViewSet
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
router.register(r'externals', ExternalViewSet)
router.register(r'chat-access', ChatAccessViewSet)
router.register(r'invitations', OrganisationInvitationViewSet)
router.register(r'bug-reports', BugReportViewSet)

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
    path('projects/<int:project_id>/externals/', get_externals_by_project, name='project-externals'),
    path('organisations/<int:org_id>/externals/', get_externals_by_organisation, name='organisation-externals'),
    path('organisations/<int:org_id>/users/', get_all_users_by_organisation, name='organisation-all-users'),
    path('organisations/<int:org_id>/users/<int:user_id>/', remove_user_from_organisation, name='remove-user-from-org'),
]

urlpatterns += [
    path('invitations/<str:token>/', get_invitation_details, name='invitation-details'),
    path('invitations/<str:token>/accept/', accept_invitation, name='accept-invitation'),
    path('invitations/<str:token>/decline/', decline_invitation, name='decline-invitation'),
    path('my-invitations/', my_invitations, name='my-invitations'),
    path('my-profile/', my_profile, name='my-profile'),
]




