# MVVM Architecture with Flutter and Django

This project implements a Flutter mobile application using the MVVM (Model-View-ViewModel) architecture pattern, connecting to your Django backend.

## Project Structure

```
lib/
├── config/                 # Configuration files
│   └── api_config.dart     # API endpoints and configuration
├── models/                 # Data models that match Django models
│   ├── calendar.dart
│   ├── event.dart
│   ├── organisation.dart
│   ├── project.dart
│   ├── status.dart
│   ├── task.dart
│   └── user.dart
├── services/               # API services for data operations
│   ├── api_client.dart     # HTTP client for API communication
│   ├── auth_service.dart   # Authentication service
│   ├── base_service.dart   # Base interface for CRUD operations
│   ├── event_service.dart  # Event-specific service
│   ├── project_service.dart # Project-specific service 
│   ├── service_registry.dart # Service locator pattern implementation
│   └── task_service.dart   # Task-specific service
└── main.dart               # Application entry point

test/                       # Test directory
├── mocks/                  # Mock objects for testing
│   └── mock_api_client.dart # Mock API client
└── services/               # Service tests
    ├── auth_service_test.dart
    ├── event_service_test.dart
    ├── project_service_test.dart
    └── task_service_test.dart
```

## Setup Instructions

1. **Install Flutter**
   
   Follow the Flutter installation guide at https://flutter.dev/docs/get-started/install

2. **Clone this repository**
   
   ```bash
   git clone <your-repository-url>
   cd <your-repository>
   ```

3. **Install dependencies**
   
   ```bash
   flutter pub get
   ```

4. **Configure API endpoint**
   
   Edit `lib/config/api_config.dart` to point to your Django backend URL.

5. **Run the tests**
   
   ```bash
   flutter test
   ```

## Using the Services

The service layer is implemented using a service registry pattern. You can access services as follows:

```dart
import 'package:your_app/services/service_registry.dart';

// Initialize the service registry (typically in main.dart)
await ServiceRegistry().initialize();

// Access a service
final projectService = ServiceRegistry().projectService;
final tasks = await projectService.getAll();

// Use authentication
final authService = ServiceRegistry().authService;
await authService.login('username', 'password');
```

## Testing

The project includes unit tests for all services. Tests use Mockito to mock the API client.

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/services/project_service_test.dart
```

## Next Steps

1. **Implement ViewModels**
   
   Create ViewModel classes that use the services and expose data to the UI.

2. **Build UI Components**
   
   Implement Flutter widgets that connect to the ViewModels.

## Service Architecture

The service layer follows these design principles:

1. **Interface Segregation**: Each service implements the `BaseService<T>` interface.

2. **Dependency Injection**: Services accept dependencies in their constructors for testability.

3. **Single Responsibility**: Each service handles operations for a specific data type.

4. **Error Handling**: API errors are properly captured and propagated.