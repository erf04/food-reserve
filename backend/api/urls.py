from django.urls import path
from . import views
urlpatterns = [
    path('get-menu/',views.ReservationView.as_view()),
    path('get-reservations/',views.get_all_reservations),
    path('reserve/',views.reserve_meal),
    path('shiftmeal/create/',views.ShiftMealAPIView.as_view()),
    path('meal/create/',views.MealAPIView.as_view()),
    path('profile/',views.ProfileAPIView.as_view()),
    path('email/',views.send_test_email),
    path('delete-reservation/<int:id>/',views.delete_reservation),
    path('pending-list/',views.ReservationView.as_view()),
    path('sms/',views.send_sms),
    path('password/reset/',views.PasswordResetRequestView.as_view()),
    path('password/reset/confirm/',views.PasswordResetConfirmView.as_view()),
    path('meal/delete/<int:id>/',views.delete_meal),
    path('manager/',views.ShiftManagerView.as_view()),
    path('reservations/all/',views.get_reservations_for_supervisor),
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('shiftmeal/filter/',views.filter_shift_meals),
    path('check-code/',views.check_code),
    path('user/update/',views.UserUpdateAPIView.as_view())
]