from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CustomTokenObtainPairView
from .views import register_user
from .views import (
    UserViewSet, OrganisationViewSet, RoleViewSet, UserOrganisationViewSet,
    CalendarViewSet, EventViewSet, ProjectViewSet, ChatViewSet, ChatUserViewSet,
    MessageViewSet, SongViewSet, TimetableViewSet, SetlistViewSet,
    HistoryViewSet, StatusViewSet, TaskViewSet, RecordingViewSet, UserProjectViewSet
)
# Update api/urls.py to include JWT views
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenVerifyView,
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