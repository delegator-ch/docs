from rest_framework import viewsets, permissions, filters
from django_filters.rest_framework import DjangoFilterBackend
from django.contrib.auth import get_user_model
from rest_framework.permissions import IsAuthenticated, AllowAny

from .models import (
    Organisation, Role, UserOrganisation, Calendar, Event, Project, Chat,
    ChatUser, Message, Song, Timetable, Setlist, History, Status, Task, Recording
)
from .serializers import (
    UserSerializer, UserDetailSerializer, OrganisationSerializer, RoleSerializer,
    UserOrganisationSerializer, CalendarSerializer, EventSerializer, EventDetailSerializer,
    ProjectSerializer, ProjectDetailSerializer, ChatSerializer, ChatUserSerializer,
    MessageSerializer, SongSerializer, TimetableSerializer, SetlistSerializer,
    HistorySerializer, StatusSerializer, TaskSerializer, RecordingSerializer
)
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status

# Add to api/views.py
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView


User = get_user_model()


@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

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

    def get_queryset(self):
        """
        This view returns only organizations the user has been invited to.
        """
        user = self.request.user
        # Get organizations where this user has a UserOrganisation relationship
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        return Organisation.objects.filter(id__in=user_orgs)

# Read only
class RoleViewSet(viewsets.ReadOnlyModelViewSet): 
    queryset = Role.objects.all()
    serializer_class = RoleSerializer
    permission_classes = [IsAuthenticated] 


class UserOrganisationViewSet(viewsets.ModelViewSet):
    queryset = UserOrganisation.objects.all()
    serializer_class = UserOrganisationSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['organisation', 'role']
    permission_classes = [IsAuthenticated]  # Ensures only authenticated users can access
    
    def get_queryset(self):
        """
        This view returns only UserOrganisation records for the current user.
        """
        user = self.request.user
        return UserOrganisation.objects.filter(user=user)

# acess when you are in the project or the calender has your id or 
class CalendarViewSet(viewsets.ModelViewSet):
    queryset = Calendar.objects.all()
    serializer_class = CalendarSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['organisation']
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        This view returns only calendars the user has access to, through:
        1. Being part of a project associated with the calendar
        2. Being part of the organization that owns the calendar with specific roles
        3. The calendar is specifically associated with the user (user-specific calendars)
        """
        user = self.request.user
        
        # Get organizations the user belongs to with specific roles
        specific_roles = [1, 2, 3]  # IDs of roles that should grant calendar access
        user_orgs = UserOrganisation.objects.filter(
            user=user, 
            role_id__in=specific_roles
        ).values_list('organisation_id', flat=True)
        
        # Get calendars from those organizations
        user_calendars = Calendar.objects.filter(organisation_id__in=user_orgs)
        
        # Get projects the user is part of (via tasks)
        user_projects = Project.objects.filter(task__user=user).distinct()
        
        # Get events from those projects
        project_events = Event.objects.filter(project__in=user_projects).values_list('calendar_id', flat=True).distinct()
        
        # Get calendars from those events
        project_calendars = Calendar.objects.filter(id__in=project_events)
        
        # Get user-specific calendars 
        # You'll need to add a user field to your Calendar model for this to work
        user_specific_calendars = Calendar.objects.filter(user=user)
        
        # Combine all querysets
        return (user_calendars | project_calendars | user_specific_calendars).distinct()

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


class HistoryViewSet(viewsets.ModelViewSet):
    queryset = History.objects.all()
    serializer_class = HistorySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['user']
    search_fields = ['activity']

#Roles are defined by me not the user
class StatusViewSet(viewsets.ReadOnlyModelViewSet): 
    queryset = Status.objects.all()
    serializer_class = StatusSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']
    permission_classes = [IsAuthenticated]


class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['user', 'project', 'status', 'deadline', 'event']
    search_fields = ['title', 'content']


class RecordingViewSet(viewsets.ModelViewSet):
    queryset = Recording.objects.all()
    serializer_class = RecordingSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project', 'song']


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        
        # Add custom claims to the token payload
        token['username'] = user.username
        token['email'] = user.email
        token['first_name'] = user.first_name
        token['last_name'] = user.last_name
        
        return token

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer