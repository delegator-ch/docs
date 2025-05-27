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
    Task, Recording, External, ChatAccessView
)

from .serializers import (
    UserSerializer, UserDetailSerializer, OrganisationSerializer, RoleSerializer,
    UserOrganisationSerializer, CalendarSerializer, EventSerializer, EventDetailSerializer,
    ProjectSerializer, ProjectDetailSerializer, ChatSerializer, ChatUserSerializer,
    MessageSerializer, SongSerializer, TimetableSerializer, SetlistSerializer,
    HistorySerializer, StatusSerializer, TaskSerializer, RecordingSerializer,
    ExternalSerializer, ChatAccessSerializer
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
        user = self.request.user
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        return Organisation.objects.filter(id__in=user_orgs)
    
    def create(self, request, *args, **kwargs):
        if not request.user.is_premium:
            return Response(
                {"detail": "Only premium users can create organizations."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().create(request, *args, **kwargs)
    
    def perform_create(self, serializer):
        organisation = serializer.save()
        admin_role = Role.objects.get(name='Admin')
        UserOrganisation.objects.create(
            user=self.request.user,
            organisation=organisation,
            role=admin_role
        )
        
class RoleViewSet(viewsets.ReadOnlyModelViewSet): 
    queryset = Role.objects.all()
    serializer_class = RoleSerializer
    permission_classes = [IsAuthenticated] 
 
# This only shows organizations where YOU are a member. It doesn't show other users in your organizations. 
class UserOrganisationViewSet(viewsets.ModelViewSet):
    queryset = UserOrganisation.objects.all()
    serializer_class = UserOrganisationSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['organisation', 'role']
    permission_classes = [IsAuthenticated] 
    
    def get_queryset(self):
        user = self.request.user
        return UserOrganisation.objects.filter(user=user)

class CalendarViewSet(viewsets.ModelViewSet):
    queryset = Calendar.objects.all().order_by('id')
    serializer_class = CalendarSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return get_user_accessible_calendars(self.request.user).order_by('id')
    
    def create(self, request, *args, **kwargs):
        organisation_id = request.data.get('organisation')
        project_id = request.data.get('project')
        
        if project_id:
            try:
                project = Project.objects.get(id=project_id)
                has_project_access = External.objects.filter(user=request.user, project=project).exists()
                if has_project_access:
                    return super().create(request, *args, **kwargs)
            except Project.DoesNotExist:
                pass
        
        if organisation_id:
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

class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event', 'priority', 'status']
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProjectDetailSerializer
        return ProjectSerializer
    
    def get_queryset(self):
        user = self.request.user
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        
        org_projects = Project.objects.filter(organisation_id__in=user_orgs)
        direct_projects = Project.objects.filter(external__user=user)
        
        return (org_projects | direct_projects).distinct()
    
    def create(self, request, *args, **kwargs):
        event_id = request.data.get('event')
        
        if event_id:
            try:
                event = Event.objects.select_related('calendar__organisation').get(id=event_id)
                organisation = event.calendar.organisation
                
                if not UserOrganisation.objects.filter(user=request.user, organisation=organisation).exists():
                    return Response(
                        {"detail": "You can only create projects in organizations you belong to."},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except Event.DoesNotExist:
                pass
        
        return super().create(request, *args, **kwargs)

class ChatViewSet(viewsets.ModelViewSet):
    queryset = Chat.objects.all()
    serializer_class = ChatSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        
        if user.is_staff:
            return Chat.objects.select_related('project', 'organisation').all()
        
        direct_chats = Chat.objects.filter(
            chatuser__user=user, 
            chatuser__view=True
        ).select_related('project', 'organisation')
        
        project_chats = Chat.objects.filter(
            project__external__user=user
        ).select_related('project', 'organisation')
        
        org_chats = Chat.objects.filter(
            organisation__userorganisation__user=user,
            organisation__userorganisation__role__level__lte=F('min_role_level')
        ).select_related('project', 'organisation')
        
        return (direct_chats | project_chats | org_chats).distinct()

    def create(self, request, *args, **kwargs):
        user = request.user
        org_id = request.data.get('organisation')
        project_id = request.data.get('project')

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

        return super().create(request, *args, **kwargs)

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
    permission_classes = [IsAuthenticated, IsMessageOwnerOrReadOnly]

    def get_queryset(self):
        return Message.objects.filter(chat__in=get_user_accessible_chats(self.request.user))

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def perform_update(self, serializer):
        serializer.save(edited=timezone.now())

class SongViewSet(viewsets.ModelViewSet):
    queryset = Song.objects.all()
    serializer_class = SongSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['nr']
    search_fields = ['name', 'description']
    permission_classes = [IsAuthenticated, HasSongPermission]
    
    def get_queryset(self):
        user = self.request.user
        
        if user.is_staff:
            return Song.objects.all()
        
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        
        return Song.objects.filter(
            organisation_id__in=user_orgs
        ).distinct()

class TimetableViewSet(viewsets.ModelViewSet):
    queryset = Timetable.objects.all().order_by('id')
    serializer_class = TimetableSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event']
    search_fields = ['name']
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        
        if user.is_staff:
            return Timetable.objects.all().order_by('id')
        
        user_projects = Project.objects.filter(external__user=user)
        project_events = Event.objects.filter(project__in=user_projects)
        
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        org_calendars = Calendar.objects.filter(organisation_id__in=user_orgs)
        org_events = Event.objects.filter(calendar__in=org_calendars)
        
        accessible_events = (project_events | org_events).distinct()
        
        return Timetable.objects.filter(event__in=accessible_events).order_by('id')
    
    def check_permissions(self, request):
        if self.action in ['list', 'retrieve'] and request.user.is_authenticated:
            return True
        
        return super().check_permissions(request)

class SetlistViewSet(viewsets.ModelViewSet):
    queryset = Setlist.objects.all()
    serializer_class = SetlistSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['event', 'song']
    search_fields = ['name']
    permission_classes = [IsAuthenticated, IsProjectMember]

    def get_queryset(self):
        user = self.request.user
        
        if user.is_staff:
            return Setlist.objects.all()
            
        user_projects = Project.objects.filter(external__user=user)
        project_events = Event.objects.filter(project__in=user_projects)
        
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        org_calendars = Calendar.objects.filter(organisation_id__in=user_orgs)
        org_events = Event.objects.filter(calendar__in=org_calendars)
        
        accessible_events = (project_events | org_events).distinct()
        
        return Setlist.objects.filter(event__in=accessible_events)

class HistoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = History.objects.all()
    serializer_class = HistorySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['user']
    search_fields = ['activity']
    permission_classes = [IsAuthenticated, IsPartOfOrganisationAndStaff]
    
    def get_queryset(self):
        user = self.request.user
        
        if user.is_staff:
            return History.objects.all()
            
        return History.objects.filter(user=user)

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
    filterset_fields = ['project', 'status', 'deadline', 'event']
    search_fields = ['title', 'content']
    permission_classes = [IsAuthenticated, IsProjectMember]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return Task.objects.all()
            
        # Return tasks that the user can access
        return Task.objects.filter(
            Q(user=user) |  # User's own tasks
            Q(project__external__user=user) |  # Tasks in projects user is member of
            Q(project__organisation__userorganisation__user=user)  # Tasks in org projects
        ).distinct()

    def perform_create(self, serializer):
        # The permission check is already done in has_permission
        # Just save with the current user
        serializer.save(user=self.request.user)

class RecordingViewSet(viewsets.ModelViewSet):
    queryset = Recording.objects.all()
    serializer_class = RecordingSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project', 'song']
    permission_classes = [IsAuthenticated, IsProjectMember]

    def get_queryset(self):
        return get_user_project_queryset(self.request.user, self.queryset, project_field='project')

class ExternalViewSet(viewsets.ModelViewSet):
    queryset = External.objects.all()
    serializer_class = ExternalSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['user', 'project', 'role']
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return External.objects.all()
        
        user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
        accessible_projects = Project.objects.filter(organisation_id__in=user_orgs)
        
        return External.objects.filter(project__in=accessible_projects)

class ChatAccessViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ChatAccessView.objects.all()
    serializer_class = ChatAccessSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['chat_id', 'user_id', 'access_type']
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return ChatAccessView.objects.all()
        
        accessible_chat_ids = ChatAccessView.objects.filter(user_id=user.id).values_list('chat_id', flat=True)
        return ChatAccessView.objects.filter(chat_id__in=accessible_chat_ids)

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        
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
    user = request.user
    user.is_premium = True
    user.save()
    
    return Response({
        "detail": "Congratulations! You are now a premium user.",
        "is_premium": True
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_users_by_project(request, project_id):
    try:
        project = Project.objects.get(id=project_id)
    except Project.DoesNotExist:
        return Response(
            {"detail": "Project not found."},
            status=status.HTTP_404_NOT_FOUND
        )
    
    user = request.user
    if not user.is_staff:
        has_project_access = External.objects.filter(user=user, project=project).exists()
        has_org_access = UserOrganisation.objects.filter(
            user=user, 
            organisation=project.organisation
        ).exists() if hasattr(project, 'organisation') else False
        
        if not (has_project_access or has_org_access):
            return Response(
                {"detail": "You don't have access to this project."},
                status=status.HTTP_403_FORBIDDEN
            )
    
    users_data = []
    added_user_ids = set()
    
    externals = External.objects.filter(project=project).select_related('user', 'role')
    for ext in externals:
        users_data.append({
            'id': ext.user.id,
            'username': ext.user.username,
            'email': ext.user.email,
            'first_name': ext.user.first_name,
            'last_name': ext.user.last_name,
            'role': {
                'id': ext.role.id,
                'name': ext.role.name,
                'level': ext.role.level
            },
            'joined_project': ext.created,
            'access_type': 'external'
        })
        added_user_ids.add(ext.user.id)

    if hasattr(project, 'organisation') and project.organisation:
        org_users = UserOrganisation.objects.filter(
            organisation=project.organisation,
            role_id__in=[1, 2, 3]
        ).select_related('user', 'role')
        
        for uo in org_users:
            if uo.user.id not in added_user_ids:
                users_data.append({
                    'id': uo.user.id,
                    'username': uo.user.username,
                    'email': uo.user.email,
                    'first_name': uo.user.first_name,
                    'last_name': uo.user.last_name,
                    'role': {
                        'id': uo.role.id,
                        'name': uo.role.name,
                        'level': uo.role.level
                    },
                    'joined_project': None,
                    'access_type': 'organization'
                })
                added_user_ids.add(uo.user.id)
    
    return Response({
        'project_id': project.id,
        'project_name': project.name,
        'users': users_data,
        'total_users': len(users_data)
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_externals_by_project(request, project_id):
    try:
        project = Project.objects.get(id=project_id)
    except Project.DoesNotExist:
        return Response(
            {"detail": "Project not found."},
            status=status.HTTP_404_NOT_FOUND
        )
    
    user = request.user
    if not user.is_staff:
        has_project_access = External.objects.filter(user=user, project=project).exists()
        has_org_access = UserOrganisation.objects.filter(
            user=user, 
            organisation=project.organisation
        ).exists() if hasattr(project, 'organisation') else False
        
        if not (has_project_access or has_org_access):
            return Response(
                {"detail": "You don't have access to this project."},
                status=status.HTTP_403_FORBIDDEN
            )
    
    externals = External.objects.filter(project=project).select_related('user', 'role')
    serializer = ExternalSerializer(externals, many=True)
    
    return Response({
        'project_id': project.id,
        'project_name': project.name,
        'externals': serializer.data,
        'total_externals': externals.count()
    })
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_externals_by_organisation(request, org_id):
    try:
        organisation = Organisation.objects.get(id=org_id)
    except Organisation.DoesNotExist:
        return Response(
            {"detail": "Organisation not found."},
            status=status.HTTP_404_NOT_FOUND
        )
    
    user = request.user
    if not user.is_staff:
        has_org_access = UserOrganisation.objects.filter(
            user=user, 
            organisation=organisation
        ).exists()
        
        if not has_org_access:
            return Response(
                {"detail": "You don't have access to this organisation."},
                status=status.HTTP_403_FORBIDDEN
            )
    
    # Get all users with role 6 (external) in this organisation
    external_users = UserOrganisation.objects.filter(
        organisation=organisation,
        role_id=6
    ).select_related('user', 'role')
    
    serializer = UserOrganisationSerializer(external_users, many=True)
    
    return Response({
        'organisation_id': organisation.id,
        'organisation_name': organisation.name,
        'external_users': serializer.data,
        'total_external_users': external_users.count()
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_all_users_by_organisation(request, org_id):
    try:
        organisation = Organisation.objects.get(id=org_id)
    except Organisation.DoesNotExist:
        return Response(
            {"detail": "Organisation not found."},
            status=status.HTTP_404_NOT_FOUND
        )
    
    user = request.user
    if not user.is_staff:
        # Check if user is admin in this org (assuming role_id=1 is admin)
        is_admin = UserOrganisation.objects.filter(
            user=user, 
            organisation=organisation,
            role_id=1
        ).exists()
        
        if not is_admin:
            return Response(
                {"detail": "Only admins can view all users in this organisation."},
                status=status.HTTP_403_FORBIDDEN
            )
    
    # Get all users in this organisation
    all_users = UserOrganisation.objects.filter(
        organisation=organisation
    ).select_related('user', 'role')
    
    serializer = UserOrganisationSerializer(all_users, many=True)
    
    return Response({
        'organisation_id': organisation.id,
        'organisation_name': organisation.name,
        'users': serializer.data,
        'total_users': all_users.count()
    })

# Add this to views.py

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def remove_user_from_organisation(request, org_id, user_id):
    """
    Remove a user from an organisation. Only admins can do this.
    """
    try:
        organisation = Organisation.objects.get(id=org_id)
        target_user = User.objects.get(id=user_id)
    except (Organisation.DoesNotExist, User.DoesNotExist):
        return Response(
            {"detail": "Organisation or user not found."},
            status=status.HTTP_404_NOT_FOUND
        )
    
    user = request.user
    if not user.is_staff:
        # Check if user is admin in this org (role_id=1)
        is_admin = UserOrganisation.objects.filter(
            user=user, 
            organisation=organisation,
            role_id=1  # Assuming role_id=1 is admin
        ).exists()
        
        if not is_admin:
            return Response(
                {"detail": "Only admins can remove users from this organisation."},
                status=status.HTTP_403_FORBIDDEN
            )
    
    # Prevent removing yourself if you're the only admin
    if target_user == user:
        admin_count = UserOrganisation.objects.filter(
            organisation=organisation,
            role_id=1
        ).count()
        
        if admin_count == 1:
            return Response(
                {"detail": "Cannot remove yourself - you're the only admin."},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    # Remove the user from organisation
    try:
        user_org = UserOrganisation.objects.get(
            user=target_user,
            organisation=organisation
        )
        user_org.delete()
        
        return Response(
            {"detail": f"User {target_user.username} removed from {organisation.name}."},
            status=status.HTTP_200_OK
        )
    except UserOrganisation.DoesNotExist:
        return Response(
            {"detail": "User is not a member of this organisation."},
            status=status.HTTP_404_NOT_FOUND
        )