from rest_framework import viewsets, permissions, filters
from django_filters.rest_framework import DjangoFilterBackend
from django.contrib.auth import get_user_model
from .models import (
    Organisation, Role, UserOrganisation, Calendar, Event, Project, Chat,
    ChatUser, Message, Song, Timetable, Setlist, Contact, ContactEvent,
    Email, History, Status, Task, Recording, Moodboard, Mood, Audio,
    AudioComment, Storyboard, Retro, Question, Evaluation, Vote, Account,
    Transaction, Type, Piece, PieceType, Stack, StackMovement, Vision,
    Meeting, TalkingPoint, Decision
)
from .serializers import (
    UserSerializer, UserDetailSerializer, OrganisationSerializer, RoleSerializer,
    UserOrganisationSerializer, CalendarSerializer, EventSerializer, EventDetailSerializer,
    ProjectSerializer, ProjectDetailSerializer, ChatSerializer, ChatUserSerializer,
    MessageSerializer, SongSerializer, TimetableSerializer, SetlistSerializer,
    ContactSerializer, ContactEventSerializer, EmailSerializer, HistorySerializer,
    StatusSerializer, TaskSerializer, RecordingSerializer, MoodboardSerializer,
    MoodSerializer, AudioSerializer, AudioCommentSerializer, StoryboardSerializer,
    RetroSerializer, QuestionSerializer, EvaluationSerializer, VoteSerializer,
    AccountSerializer, TransactionSerializer, TypeSerializer, PieceSerializer,
    PieceTypeSerializer, StackSerializer, StackMovementSerializer, VisionSerializer,
    MeetingSerializer, MeetingDetailSerializer, TalkingPointSerializer, DecisionSerializer
)

User = get_user_model()


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['username', 'email']
    search_fields = ['username', 'email', 'first_name', 'last_name']
    
    def get_serializer_class(self):
        if self.action == 'retrieve' or self.action == 'list':
            return UserDetailSerializer
        return UserSerializer


class OrganisationViewSet(viewsets.ModelViewSet):
    queryset = Organisation.objects.all()
    serializer_class = OrganisationSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['name']
    search_fields = ['name']


class RoleViewSet(viewsets.ModelViewSet):
    queryset = Role.objects.all()
    serializer_class = RoleSerializer


class UserOrganisationViewSet(viewsets.ModelViewSet):
    queryset = UserOrganisation.objects.all()
    serializer_class = UserOrganisationSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['user', 'organisation', 'role']


class CalendarViewSet(viewsets.ModelViewSet):
    queryset = Calendar.objects.all()
    serializer_class = CalendarSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['organisation']


class EventViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['calendar', 'is_gig']
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return EventDetailSerializer
        return EventSerializer


class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event', 'priority']
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProjectDetailSerializer
        return ProjectSerializer


class ChatViewSet(viewsets.ModelViewSet):
    queryset = Chat.objects.all()
    serializer_class = ChatSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']


class ChatUserViewSet(viewsets.ModelViewSet):
    queryset = ChatUser.objects.all()
    serializer_class = ChatUserSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['user', 'chat', 'view', 'write']


class MessageViewSet(viewsets.ModelViewSet):
    queryset = Message.objects.all()
    serializer_class = MessageSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['user', 'chat']
    search_fields = ['content']


class SongViewSet(viewsets.ModelViewSet):
    queryset = Song.objects.all()
    serializer_class = SongSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['nr']
    search_fields = ['name', 'description']


class TimetableViewSet(viewsets.ModelViewSet):
    queryset = Timetable.objects.all()
    serializer_class = TimetableSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event']
    search_fields = ['name']


class SetlistViewSet(viewsets.ModelViewSet):
    queryset = Setlist.objects.all()
    serializer_class = SetlistSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event', 'song']
    search_fields = ['name']


class ContactViewSet(viewsets.ModelViewSet):
    queryset = Contact.objects.all()
    serializer_class = ContactSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    search_fields = ['first_name', 'name', 'email', 'phone']


class ContactEventViewSet(viewsets.ModelViewSet):
    queryset = ContactEvent.objects.all()
    serializer_class = ContactEventSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['event', 'contact']


class EmailViewSet(viewsets.ModelViewSet):
    queryset = Email.objects.all()
    serializer_class = EmailSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['event', 'sender']


class HistoryViewSet(viewsets.ModelViewSet):
    queryset = History.objects.all()
    serializer_class = HistorySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['user']
    search_fields = ['activity']


class StatusViewSet(viewsets.ModelViewSet):
    queryset = Status.objects.all()
    serializer_class = StatusSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']


class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['user', 'project', 'status', 'deadline', 'event']
    search_fields = ['title', 'content']


class RecordingViewSet(viewsets.ModelViewSet):
    queryset = Recording.objects.all()
    serializer_class = RecordingSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['project', 'song']
    search_fields = ['title', 'description']


class MoodboardViewSet(viewsets.ModelViewSet):
    queryset = Moodboard.objects.all()
    serializer_class = MoodboardSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']


class MoodViewSet(viewsets.ModelViewSet):
    queryset = Mood.objects.all()
    serializer_class = MoodSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['moodboard']


class AudioViewSet(viewsets.ModelViewSet):
    queryset = Audio.objects.all()
    serializer_class = AudioSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['song', 'user', 'project']
    search_fields = ['description']


class AudioCommentViewSet(viewsets.ModelViewSet):
    queryset = AudioComment.objects.all()
    serializer_class = AudioCommentSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['audio', 'user']
    search_fields = ['content']


class StoryboardViewSet(viewsets.ModelViewSet):
    queryset = Storyboard.objects.all()
    serializer_class = StoryboardSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project', 'user']


class RetroViewSet(viewsets.ModelViewSet):
    queryset = Retro.objects.all()
    serializer_class = RetroSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event', 'has_been_checked']
    search_fields = ['learning']


class QuestionViewSet(viewsets.ModelViewSet):
    queryset = Question.objects.all()
    serializer_class = QuestionSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'name']


class EvaluationViewSet(viewsets.ModelViewSet):
    queryset = Evaluation.objects.all()
    serializer_class = EvaluationSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['question', 'user', 'rating']
    search_fields = ['comment']


class VoteViewSet(viewsets.ModelViewSet):
    queryset = Vote.objects.all()
    serializer_class = VoteSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['user', 'vote']


class AccountViewSet(viewsets.ModelViewSet):
    queryset = Account.objects.all()
    serializer_class = AccountSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['project']
    search_fields = ['name']


class TransactionViewSet(viewsets.ModelViewSet):
    queryset = Transaction.objects.all()
    serializer_class = TransactionSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['user', 'soll_account', 'haben_account']


class TypeViewSet(viewsets.ModelViewSet):
    queryset = Type.objects.all()
    serializer_class = TypeSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['project']
    search_fields = ['name']


class PieceViewSet(viewsets.ModelViewSet):
    queryset = Piece.objects.all()
    serializer_class = PieceSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['serial']
    search_fields = ['name']


class PieceTypeViewSet(viewsets.ModelViewSet):
    queryset = PieceType.objects.all()
    serializer_class = PieceTypeSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['type', 'piece']


class StackViewSet(viewsets.ModelViewSet):
    queryset = Stack.objects.all()
    serializer_class = StackSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['piece', 'size']


class StackMovementViewSet(viewsets.ModelViewSet):
    queryset = StackMovement.objects.all()
    serializer_class = StackMovementSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['stack', 'user']


class VisionViewSet(viewsets.ModelViewSet):
    queryset = Vision.objects.all()
    serializer_class = VisionSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['project', 'priority']
    search_fields = ['title', 'content']


class MeetingViewSet(viewsets.ModelViewSet):
    queryset = Meeting.objects.all()
    serializer_class = MeetingSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return MeetingDetailSerializer
        return MeetingSerializer


class TalkingPointViewSet(viewsets.ModelViewSet):
    queryset = TalkingPoint.objects.all()
    serializer_class = TalkingPointSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['meeting', 'user']
    search_fields = ['title', 'content']


class DecisionViewSet(viewsets.ModelViewSet):
    queryset = Decision.objects.all()
    serializer_class = DecisionSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['meeting']
    search_fields = ['content']