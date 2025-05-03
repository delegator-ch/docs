from rest_framework import viewsets, permissions, filters
from django_filters.rest_framework import DjangoFilterBackend
from django.contrib.auth import get_user_model
from rest_framework.permissions import IsAuthenticated, AllowAny

from .models import (
    Organisation, Role, UserOrganisation, Calendar, Event, Project, Chat,
    ChatUser, Message, Song, Timetable, Setlist, History, Status, Task, Recording, UserProject, ChatAccessView
)
from .serializers import (
    UserSerializer, UserDetailSerializer, OrganisationSerializer, RoleSerializer,
    UserOrganisationSerializer, CalendarSerializer, EventSerializer, EventDetailSerializer,
    ProjectSerializer, ProjectDetailSerializer, ChatSerializer, ChatUserSerializer,
    MessageSerializer, SongSerializer, TimetableSerializer, SetlistSerializer,
    HistorySerializer, StatusSerializer, TaskSerializer, RecordingSerializer, UserProjectSerializer, ChatAccessSerializer
)

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status

from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from .permissions import CanAccessCalendar
from .utils import get_user_accessible_calendars
from .permissions import CanAccessChat

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
        This view returns only calendars the user has access to.
        """
        return get_user_accessible_calendars(self.request.user)

#acces only via calender access
class EventViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['calendar', 'is_gig']
    permission_classes = [IsAuthenticated, CanAccessCalendar]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return EventDetailSerializer
        return EventSerializer

    def get_queryset(self):
        return Event.objects.filter(calendar__in=get_user_accessible_calendars(self.request.user))

# Everbody can create Projects but only in organisations they where added to and as a user you only acces project you were you are added to 
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
    permission_classes = [IsAuthenticated, CanAccessChat]
    
    def get_queryset(self):
        """
        Filter chats to only those the user has access to.
        """
        user = self.request.user
        
        # Admin/staff can see all chats
        if user.is_staff:
            return Chat.objects.all()
            
        # Get projects the user is a member of
        user_projects = Project.objects.filter(userproject__user=user)
        
        # Get user's organizations
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        
        # Get chats where user is explicitly added
        user_chats = Chat.objects.filter(chatuser__user=user, chatuser__view=True)
        
        # Get chats from user's projects
        project_chats = Chat.objects.filter(project__in=user_projects)
        
        # Combine the querysets (we need to determine how to get org-based chats)
        return (user_chats | project_chats).distinct()


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

class UserProjectViewSet(viewsets.ModelViewSet):
    queryset = UserProject.objects.all()
    serializer_class = UserProjectSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['user', 'project', 'role']
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        This view returns UserProject records filtered by the current user
        if they're not a staff member.
        """
        user = self.request.user
        if user.is_staff:
            return UserProject.objects.all()
        return UserProject.objects.filter(
            models.Q(user=user) | 
            models.Q(project__in=Project.objects.filter(userproject__user=user))
        ).distinct()

class ChatAccessViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ChatAccessView.objects.all()
    serializer_class = ChatAccessSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['chat_id', 'user_id', 'access_type']
    
    def get_queryset(self):
        # Only show access for chats the user can access
        user = self.request.user
        if user.is_staff:
            return ChatAccessView.objects.all()
        
        # Get chat IDs this user can access
        accessible_chat_ids = ChatAccessView.objects.filter(user_id=user.id).values_list('chat_id', flat=True)
        return ChatAccessView.objects.filter(chat_id__in=accessible_chat_ids)

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