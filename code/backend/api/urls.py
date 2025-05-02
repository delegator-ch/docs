from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserViewSet, OrganisationViewSet, RoleViewSet, UserOrganisationViewSet,
    CalendarViewSet, EventViewSet, ProjectViewSet, ChatViewSet, ChatUserViewSet,
    MessageViewSet, SongViewSet, TimetableViewSet, SetlistViewSet, ContactViewSet,
    ContactEventViewSet, EmailViewSet, HistoryViewSet, StatusViewSet, TaskViewSet,
    RecordingViewSet, MoodboardViewSet, MoodViewSet, AudioViewSet, AudioCommentViewSet,
    StoryboardViewSet, RetroViewSet, QuestionViewSet, EvaluationViewSet, VoteViewSet,
    AccountViewSet, TransactionViewSet, TypeViewSet, PieceViewSet, PieceTypeViewSet,
    StackViewSet, StackMovementViewSet, VisionViewSet, MeetingViewSet, TalkingPointViewSet,
    DecisionViewSet
)

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'organisations', OrganisationViewSet)
router.register(r'roles', RoleViewSet)
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
router.register(r'contacts', ContactViewSet)
router.register(r'contact-events', ContactEventViewSet)
router.register(r'emails', EmailViewSet)
router.register(r'history', HistoryViewSet)
router.register(r'statuses', StatusViewSet)
router.register(r'tasks', TaskViewSet)
router.register(r'recordings', RecordingViewSet)
router.register(r'moodboards', MoodboardViewSet)
router.register(r'moods', MoodViewSet)
router.register(r'audios', AudioViewSet)
router.register(r'audio-comments', AudioCommentViewSet)
router.register(r'storyboards', StoryboardViewSet)
router.register(r'retros', RetroViewSet)
router.register(r'questions', QuestionViewSet)
router.register(r'evaluations', EvaluationViewSet)
router.register(r'votes', VoteViewSet)
router.register(r'accounts', AccountViewSet)
router.register(r'transactions', TransactionViewSet)
router.register(r'types', TypeViewSet)
router.register(r'pieces', PieceViewSet)
router.register(r'piece-types', PieceTypeViewSet)
router.register(r'stacks', StackViewSet)
router.register(r'stack-movements', StackMovementViewSet)
router.register(r'visions', VisionViewSet)
router.register(r'meetings', MeetingViewSet)
router.register(r'talking-points', TalkingPointViewSet)
router.register(r'decisions', DecisionViewSet)

# This line is crucial - make sure it exists at the bottom of the file
urlpatterns = router.urls