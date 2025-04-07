from django.urls import path
from .views import user_register, user_login, user_logout, send_reset_password_email, reset_password_confirm
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('register/', user_register, name="user-register"),
    path('login/', user_login, name="user-login"),
    path('logout/', user_logout, name="user-logout"),
    path('password_reset/', send_reset_password_email, name='password_reset'),
    path('password_reset_confirm/', reset_password_confirm, name='password_reset_confirm'),
    path('token/refresh/', TokenRefreshView.as_view(), name="token_refresh"),  
]