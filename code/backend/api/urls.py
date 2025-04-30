# Add this to your app's urls.py
urlpatterns = [
    # ... existing urls
    path('chat/', views.chat_view, name='chat'),
]