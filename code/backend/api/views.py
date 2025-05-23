from django.utils import timezone
from django.db.models import Q, F
from django.contrib.auth import get_user_model



from rest_framework import viewsets, status, filters
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from rest_framework import status

from django_filters.rest_framework import DjangoFilterBackend

from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import (
    Organisation, Role, UserOrganisation, Calendar, Event, Project, Chat,
    ChatUser, Message, Song, Timetable, Setlist, History, Status,
    Task, Recording, UserProject, ChatAccessView
)

from .serializers import (
    UserSerializer, UserDetailSerializer, OrganisationSerializer, RoleSerializer,
    UserOrganisationSerializer, CalendarSerializer, EventSerializer, EventDetailSerializer,
    ProjectSerializer, ProjectDetailSerializer, ChatSerializer, ChatUserSerializer,
    MessageSerializer, SongSerializer, TimetableSerializer, SetlistSerializer,
    HistorySerializer, StatusSerializer, TaskSerializer, RecordingSerializer,
    UserProjectSerializer, ChatAccessSerializer
)

from .permissions import CanAccessCalendar, CanAccessChat, HasSongPermission, IsMessageOwnerOrReadOnly, IsProjectMember, IsPartOfOrganisationAndStaff, HasProjectAccess
from .utils import get_user_accessible_calendars, get_user_accessible_chats, user_has_chat_access, get_user_project_events, get_user_accessible_calendars, get_user_project_queryset, check_project_access

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
    
    def create(self, request, *args, **kwargs):
        """Check if user is premium before allowing organization creation"""
        if not request.user.is_premium:
            return Response(
                {"detail": "Only premium users can create organizations."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().create(request, *args, **kwargs)
    
    def perform_create(self, serializer):
        """When an organization is created, add the creating user as admin"""
        organisation = serializer.save()
        
        # Get admin role
        admin_role = Role.objects.get(name='Admin')  # Adjust as needed
        
        # Create UserOrganisation relationship
        UserOrganisation.objects.create(
            user=self.request.user,
            organisation=organisation,
            role=admin_role
        )
        
# Read only
class RoleViewSet(viewsets.ReadOnlyModelViewSet): 
    queryset = Role.objects.all()
    serializer_class = RoleSerializer
    permission_classes = [IsAuthenticated] 
 
# Ensures only authenticated users can access
class UserOrganisationViewSet(viewsets.ModelViewSet):
    queryset = UserOrganisation.objects.all()
    serializer_class = UserOrganisationSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['organisation', 'role']
    permission_classes = [IsAuthenticated] 
    
    def get_queryset(self):
        """
        This view returns only UserOrganisation records for the current user.
        """
        user = self.request.user
        return UserOrganisation.objects.filter(user=user)

# acess when you are in the project or the calender has your id or 
class CalendarViewSet(viewsets.ModelViewSet):
    queryset = Calendar.objects.all().order_by('id')  # Add default ordering
    serializer_class = CalendarSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return get_user_accessible_calendars(self.request.user).order_by('id')  # Add order_by here too
    
    def create(self, request, *args, **kwargs):
        """
        Check if user belongs to the organization before creating a calendar.
        """
        organisation_id = request.data.get('organisation')
        
        # If created as part of a project, check project permissions
        project_id = request.data.get('project')
        if project_id:
            try:
                project = Project.objects.get(id=project_id)
                # Check if user has access to this project
                has_project_access = UserProject.objects.filter(user=request.user, project=project).exists()
                if has_project_access:
                    return super().create(request, *args, **kwargs)
            except Project.DoesNotExist:
                pass
        
        # Otherwise check organization permissions
        if organisation_id:
            # Check if user belongs to this organization
            has_org_access = UserOrganisation.objects.filter(
                user=request.user,
                organisation_id=organisation_id
            ).exists()
            
            if not has_org_access:
                return Response(
                    {"detail": "You can only create calendars in organizations you belong to."},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        return super().create(request, *args, **kwargs)

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

# Access via Org and Role
# Access via UserProject 
class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event', 'priority', 'status']  # Added 'status' here
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProjectDetailSerializer
        return ProjectSerializer
    
    def get_queryset(self):
        user = self.request.user
        print(f"User: {user.username}")
        
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        print(f"User orgs IDs: {list(user_orgs)}")
        
        # Check if projects exist at all
        all_projects = Project.objects.all()
        print(f"Total projects in system: {all_projects.count()}")
        
        # Check org projects
        org_projects = Project.objects.filter(
            organisation_id__in=user_orgs
        )
        print(f"Projects via org membership: {org_projects.count()}")
        
        # Check direct projects
        direct_projects = Project.objects.filter(userproject__user=user)
        print(f"Projects via direct assignment: {direct_projects.count()}")
        
        result = (org_projects | direct_projects).distinct()
        print(f"Final result count: {result.count()}")
    
        return result
    
    def create(self, request, *args, **kwargs):
        """
        Check if user belongs to the organization before creating a project.
        """
        # Get the event and extract the organization
        event_id = request.data.get('event')
        
        if event_id:
            try:
                event = Event.objects.select_related('calendar__organisation').get(id=event_id)
                organisation = event.calendar.organisation
                
                # Check if user belongs to this organization
                if not UserOrganisation.objects.filter(user=request.user, organisation=organisation).exists():
                    return Response(
                        {"detail": "You can only create projects in organizations you belong to."},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except Event.DoesNotExist:
                pass  # Let the serializer handle the invalid event ID
        
        return super().create(request, *args, **kwargs)
        """
        Check if user belongs to the organization before creating a project.
        """
        # Get the event and extract the organization
        event_id = request.data.get('event')
        
        if event_id:
            try:
                event = Event.objects.select_related('calendar__organisation').get(id=event_id)
                organisation = event.calendar.organisation
                
                # Check if user belongs to this organization
                if not UserOrganisation.objects.filter(user=request.user, organisation=organisation).exists():
                    return Response(
                        {"detail": "You can only create projects in organizations you belong to."},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except Event.DoesNotExist:
                pass  # Let the serializer handle the invalid event ID
        
        return super().create(request, *args, **kwargs)

# Is only a view
class ChatViewSet(viewsets.ModelViewSet):
    queryset = Chat.objects.all()
    serializer_class = ChatSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        
        if user.is_staff:
            return Chat.objects.all()
        
        # Direct chat access
        direct_chats = Chat.objects.filter(
            chatuser__user=user, 
            chatuser__view=True
        )
        
        # Project-based chat access
        project_chats = Chat.objects.filter(
            project__userproject__user=user
        )
        
        # Organisation-based access: role level must match or exceed Chat.min_role_level
        org_chats = Chat.objects.filter(
            organisation__userorganisation__user=user,
            organisation__userorganisation__role__level__lte=F('min_role_level')
        )
        
        return (direct_chats | project_chats | org_chats).distinct()

    def create(self, request, *args, **kwargs):
        user = request.user
        org_id = request.data.get('organisation')
        project_id = request.data.get('project')

        # 🛡️ Check organisation access
        if org_id:
            has_org_access = UserOrganisation.objects.filter(
                user=user,
                organisation_id=org_id
            ).exists()

            if not has_org_access and not user.is_staff:
                return Response(
                    {"detail": "You don't have access to this organisation."},
                    status=status.HTTP_403_FORBIDDEN
                )

        # 🛡️ Check project access
        if project_id:
            has_project_access = UserProject.objects.filter(
                user=user,
                project_id=project_id
            ).exists()

            if not has_project_access and not user.is_staff:
                return Response(
                    {"detail": "You don't have access to this project."},
                    status=status.HTTP_403_FORBIDDEN
                )

        return super().create(request, *args, **kwargs)

# Only for mutingOru
class ChatUserViewSet(viewsets.ModelViewSet):
    queryset = ChatUser.objects.all()
    serializer_class = ChatUserSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['user', 'chat', 'view', 'write']

# Only access (CRUD) on projectes your are added to
# or access (CRUD) on organisation your are added to with the roles
class MessageViewSet(viewsets.ModelViewSet):
    queryset = Message.objects.all()
    serializer_class = MessageSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['user', 'chat']
    search_fields = ['content']
    permission_classes = [IsAuthenticated, IsMessageOwnerOrReadOnly]

    def get_queryset(self):
        return Message.objects.filter(chat__in=get_user_accessible_chats(self.request.user))

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def perform_update(self, serializer):
        serializer.save(edited=timezone.now())

# Access via Org
class SongViewSet(viewsets.ModelViewSet):
    queryset = Song.objects.all()
    serializer_class = SongSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['nr']
    search_fields = ['name', 'description']
    permission_classes = [IsAuthenticated, HasSongPermission]
    
    def get_queryset(self):
        """
        Filter songs based on user's organization membership.
        """
        user = self.request.user
        
        # Staff can see all songs
        if user.is_staff:
            return Song.objects.all()
        
        # Users can only see songs related to their organizations
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        
        # Filter songs belonging to user's organizations
        return Song.objects.filter(
            organisation_id__in=user_orgs
        ).distinct()

# Acces via Project
class TimetableViewSet(viewsets.ModelViewSet):
    queryset = Timetable.objects.all().order_by('id')  # Add default ordering
    serializer_class = TimetableSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event']
    search_fields = ['name']
    permission_classes = [IsAuthenticated]  # We'll handle permission in get_queryset
    
    def get_queryset(self):
        user = self.request.user
        
        # Staff can see all timetables
        if user.is_staff:
            return Timetable.objects.all().order_by('id')
        
        # Get all events the user can access
        # 1. Through project membership
        user_projects = Project.objects.filter(userproject__user=user)
        project_events = Event.objects.filter(project__in=user_projects)
        
        # 2. Through organization membership
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        org_calendars = Calendar.objects.filter(organisation_id__in=user_orgs)
        org_events = Event.objects.filter(calendar__in=org_calendars)
        
        # Combine all accessible events
        accessible_events = (project_events | org_events).distinct()
        
        # Return timetables for those events
        return Timetable.objects.filter(event__in=accessible_events).order_by('id')
    
    def check_permissions(self, request):
        # Always allow authenticated users to list and retrieve
        if self.action in ['list', 'retrieve'] and request.user.is_authenticated:
            return True
        
        # For other actions, use the default permission checks
        return super().check_permissions(request)

# Acces via Project
class SetlistViewSet(viewsets.ModelViewSet):
    queryset = Setlist.objects.all()
    serializer_class = SetlistSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event', 'song']
    search_fields = ['name']
    permission_classes = [IsAuthenticated, IsProjectMember]

    def get_queryset(self):
        user = self.request.user
        
        # Staff can access all setlists
        if user.is_staff:
            return Setlist.objects.all()
            
        # Get events from projects the user has access to
        user_projects = Project.objects.filter(userproject__user=user)
        project_events = Event.objects.filter(project__in=user_projects)
        
        # Get events from organizations the user belongs to
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        org_calendars = Calendar.objects.filter(organisation_id__in=user_orgs)
        org_events = Event.objects.filter(calendar__in=org_calendars)
        
        # Combine all accessible events
        accessible_events = (project_events | org_events).distinct()
        
        # Return setlists for accessible events
        return Setlist.objects.filter(event__in=accessible_events)

# Access via Org
class HistoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = History.objects.all()
    serializer_class = HistorySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['user']
    search_fields = ['activity']
    permission_classes = [IsAuthenticated, IsPartOfOrganisationAndStaff]
    
    def get_queryset(self):
        """
        Filter history records to only those the user has access to:
        1. History records of the user themselves
        2. Staff can see all history records
        """
        user = self.request.user
        
        # Staff can see all history records
        if user.is_staff:
            return History.objects.all()
            
        # Users can only see their own history
        return History.objects.filter(user=user)

#Roles are defined by me not the user
class StatusViewSet(viewsets.ReadOnlyModelViewSet): 
    queryset = Status.objects.all()
    serializer_class = StatusSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']
    permission_classes = [IsAuthenticated]

# Access via Project
class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['project', 'status', 'deadline', 'event']
    search_fields = ['title', 'content']
    permission_classes = [IsAuthenticated, IsProjectMember]

    def get_queryset(self):
        user = self.request.user
        return Task.objects.filter(
            Q(user=user) | Q(project__userproject__user=user) | Q(user__is_staff=True)
        ).distinct()

    def perform_create(self, serializer):
        check_project_access(self.request.user, serializer.validated_data.get('project'))
        serializer.save(user=self.request.user)

# Access via Project
class RecordingViewSet(viewsets.ModelViewSet):
    queryset = Recording.objects.all()
    serializer_class = RecordingSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project', 'song']
    permission_classes = [IsAuthenticated, IsProjectMember]

    def get_queryset(self):
        return get_user_project_queryset(self.request.user, self.queryset, project_field='project')

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

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upgrade_to_premium(request):
    """
    Endpoint to upgrade a user to premium status.
    In a real application, this would involve payment processing.
    """
    # Here you would integrate with a payment processor
    # For demonstration, we'll just set the flag
    
    user = request.user
    user.is_premium = True
    user.save()
    
    return Response({
        "detail": "Congratulations! You are now a premium user.",
        "is_premium": True
    })