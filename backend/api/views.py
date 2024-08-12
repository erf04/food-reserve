from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework import status,generics
from rest_framework import permissions
from .serializers import (MealSerializer,ShiftMealSerializer,ReservationSerializer,
ShiftSerializer,FoodSerializer,CombinedMealShiftSerializer
,CombinedFoodCreationSerializer,UserSerializer,PasswordResetRequestSerializer,PasswordResetConfirmSerializer,
DrinkSerializer,MealCreationSerializer,SupervisorRecordSerializer,SupervisorReservationSerializer,RegisterSerializer, LoginSerializer
,UserUpdateSerializer)
from rest_framework.decorators import api_view,permission_classes
from .models import ShiftMeal,Meal,Reservation,Shift,Food,FoodType,DailyMeal,User,Drink,ShiftManager,SupervisorRecord
import jdatetime
from rest_framework.views import APIView
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from .swagger_helper import token
import json
from .permissions import IsUserOrReadOnly,IsSupervisorOrReadOnly,IsUserReservation,IsShiftManagerOrReadOnly
from django.core.mail import send_mail
from django.http import HttpResponse
import jdatetime
from kavenegar import *
from django.conf import settings
from django.http import JsonResponse
from django.core.mail import EmailMultiAlternatives
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.template.loader import render_to_string
from django.utils.crypto import get_random_string
from django.db.models import Q
from django.db.models import F
from rest_framework.exceptions import ValidationError
from django.db.models.functions import Lower
from datetime import datetime
from django.shortcuts import get_object_or_404


def ISO_to_gregorian(date:str):
    jalali_date = jdatetime.date.fromisoformat(date)
    gregorian_date = jalali_date.togregorian()  
    return gregorian_date



        

class ReservationView(APIView):

    @swagger_auto_schema(
        manual_parameters=[
            token
        ],
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'date': openapi.Schema(type=openapi.TYPE_STRING, description='YYYY-MM-DD'),
                'shift': openapi.Schema(type=openapi.TYPE_STRING, description='shift name (A,B,C,D)'),
                'food1-name': openapi.Schema(type=openapi.TYPE_STRING, description='food1 name'),
                'food2-name': openapi.Schema(type=openapi.TYPE_STRING, description='food2 name'),
                'food-type':openapi.Schema(type=openapi.TYPE_STRING, description="food type ['دسر','...']"),
                'daily-meal':openapi.Schema(type=openapi.TYPE_STRING, description='[ناهار , شام]'),

            }
        ),
        operation_description="to filter the shift meals",
        responses={
            200: ShiftMealSerializer(many=True)
        }

    )
    @permission_classes([permissions.IsAuthenticated])
    def post(self,request:Request):
        filters={}
        date = request.data.get('date')
        shift_name = request.data.get('shift')
        food=request.data.get('food-name')
        # food2_name=request.data.get('food2-name')
        food_type=request.data.get('food-type')
        daily_meal=request.data.get('daily-meal')
        if date:
            gregorian_date=ISO_to_gregorian(date)
            filters["date"]=gregorian_date
        if shift_name:
            filters["shift__shift_name"]=shift_name
        if food:
            filters["meal__food__name"]=food
        if food_type:
            filters["meal__food_type"]=food_type
        if daily_meal:
            filters["meal__daily_meal"]=daily_meal
        meals = ShiftMeal.objects.filter(**filters)
        # meals=ShiftMeal.objects.filter(shift__shift_name=shift_name)
        serialized=ShiftMealSerializer(meals,many=True,context={"request":request})
        return Response(serialized.data,status=status.HTTP_200_OK)

    @swagger_auto_schema(
        manual_parameters=[token],
        responses={
            200:ReservationSerializer(many=True)
        }
    )

    @permission_classes([permissions.IsAuthenticated])
    def get(self,request:Request):
        now=jdatetime.datetime.today()
        reservations=Reservation.objects.filter(user=request.user,date__lte=F('shift_meal__date'),shift_meal__date__gte=now).order_by('shift_meal__date')
        serialized=ReservationSerializer(reservations,many=True,context={"request":request})
        return Response(data=serialized.data,status=status.HTTP_200_OK)
    


@swagger_auto_schema(
        method='get',
        operation_description="get all reserved shift meals ever",
        manual_parameters=[
            token
        ],
        responses={
            200:ShiftMealSerializer(many=True)
        }       
)
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_all_reservations(request:Request):
    my_user=request.user
    now = datetime.now()
    shift_meals=ShiftMeal.objects.filter(reservations__user=my_user,date__lt=now).order_by('date')
    serialized=ShiftMealSerializer(shift_meals,many=True,context={"request":request})
    return Response(serialized.data)


@swagger_auto_schema(
        method="post",
        operation_description="create a new reservation",
        manual_parameters=[token],
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                "shift-meal-id":openapi.Schema(type=openapi.TYPE_INTEGER,description="the shift_meal_id you want to reserve")   
            }
        ),
        responses={
            201:ReservationSerializer(many=False),
            306:"{'error'':'already reserved'}",
            410:"{'error':'shift meal doesn't exist'}",
            406:"unacceptable"
        }
)
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def reserve_meal(request:Request):
    shift_meal_id:dict = request.data.get('shift-meal-id')
    try:
        shift_meal:ShiftMeal=ShiftMeal.objects.get(id=shift_meal_id)
        daily_meal=shift_meal.meal.daily_meal
        date=shift_meal.date
        now=jdatetime.date.today()
        days_diff=(date - now).days
        if ( days_diff< 0):
            return Response(status=status.HTTP_406_NOT_ACCEPTABLE)

        other_reservation=Reservation.objects.filter(shift_meal__date=date,user=request.user,shift_meal__meal__daily_meal=daily_meal)
        print(other_reservation.exists())
        has_reserve_on_day=other_reservation.exists()
        if has_reserve_on_day:
            print("in if")
            previous_reservation=other_reservation.first()
            previous_reservation.delete()
        reservation,created=Reservation.objects.get_or_create(shift_meal=shift_meal,user=request.user,date=now)
        if not created:
            return Response(data={"error":"you have already reserve this shift meal"},status=status.HTTP_306_RESERVED)
        serialized=ReservationSerializer(reservation,many=False,context={"request":request})
        return Response(data=serialized.data,status=status.HTTP_201_CREATED)

    except ShiftMeal.DoesNotExist:
        return Response(data={"error":f"no shift meal with id {shift_meal_id}"},status=status.HTTP_410_GONE)
    
@swagger_auto_schema(
        method="DELETE",
        manual_parameters=[
            token,]
)
@api_view(['DELETE'])
@permission_classes([IsUserReservation])
def delete_reservation(request:Request,id:int):
    try:
        reservation=Reservation.objects.get(pk=id)
        reservation.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    except Reservation.DoesNotExist:
        return Response(data={"error":f"no reservation with id {id}"},status=status.HTTP_406_NOT_ACCEPTABLE)
    

    


    






class ShiftMealAPIView(APIView):
    permission_classes=[IsSupervisorOrReadOnly]

    @swagger_auto_schema(
            manual_parameters=[
                token,
                openapi.Parameter(
                    name="shift-name",
                    in_=openapi.IN_QUERY,
                    type=openapi.TYPE_STRING,
                    description="shift name (A,B,C,D)",
                    required=True
                ),
                openapi.Parameter(
                    name="date",
                    in_=openapi.IN_QUERY,
                    type=openapi.TYPE_STRING,
                    description="date with format : YYYY-MM-DD",
                    required=True
                ),
                openapi.Parameter(
                    name="meal-id",
                    type=openapi.TYPE_INTEGER,
                    in_=openapi.IN_QUERY,
                    description="meal id",
                    required=True
                ),

            ],
            operation_description="create a new shift meal",
            responses={
                400:json.dumps({"error": "shift or date or meal is required."}),
                201:ShiftMealSerializer(many=True),
                306:json.dumps({"error":"you have already create this shift meal"}),
                204:json.dumps({"error":f"there no existing meal or shift with these id's"})
            } 
    )


    def post(self,request:Request,*args,**kwargs):
        shift_name=request.data.get('shift-name')
        date=request.data.get('date')
        meal_ids=request.data.get('meal-id') 
        if not shift_name or not date or not (0<len(meal_ids)<=4):
            return Response({"error": "shift or date or meal is required."}, status=status.HTTP_400_BAD_REQUEST)
        i=0
        try:
            # remove previous shiftmeals 
            shift=Shift.objects.get(shift_name=shift_name)
            existing_shift_meals = ShiftMeal.objects.filter(shift=shift, date=ISO_to_gregorian(date))
            existing_meal_ids = set(existing_shift_meals.values_list('meal_id', flat=True))
            new_meal_ids = set(map(int, meal_ids))
            meals_to_delete = existing_meal_ids - new_meal_ids
            ShiftMeal.objects.filter(shift=shift, date=date, meal_id__in=meals_to_delete).delete()
            meals_to_add = new_meal_ids - existing_meal_ids
            for meal_id in meals_to_add:
                 # Check if we have reached the limit of 4 ShiftMeals
                 if existing_shift_meals.count() < 4:
                    meal = get_object_or_404(Meal, id=meal_id)
                    ShiftMeal.objects.create(meal=meal, shift=shift, date=date)
                    existing_shift_meals = ShiftMeal.objects.filter(shift=shift, date=date)
            # serialized=ShiftMealSerializer(shift_meal,many=False,context={"request":request})
            return Response(status=status.HTTP_201_CREATED)
        except Meal.DoesNotExist:
            return Response(data={"error":f"there no existing meal with id {meal_ids[i]}"},status=status.HTTP_204_NO_CONTENT)
        except Shift.DoesNotExist:
            return Response(data={"error":f"there no existing shift with name {shift_name}"},status=status.HTTP_204_NO_CONTENT)
        
    @swagger_auto_schema(
            operation_description="get needed fields for shiftmeal creation form",

            manual_parameters=[token],
            responses={
                200:CombinedMealShiftSerializer
            }
    )
    
    def get(self,request,*args,**kwargs):
        meals=Meal.objects.all()
        meal_serialized=MealSerializer(meals,many=True)
        shifts=Shift.objects.all()
        shift_serialized=ShiftSerializer(shifts,many=True)
        return Response(data={"meals":meal_serialized.data,"shifts":shift_serialized.data},status=status.HTTP_200_OK)
    

class MealAPIView(APIView):

    permission_classes=[IsSupervisorOrReadOnly]
    @swagger_auto_schema(
            operation_description="create a new meal",
            manual_parameters=[
                token,
                openapi.Parameter(
                    name="food1-id",
                    in_=openapi.IN_QUERY,
                    type=openapi.TYPE_INTEGER,
                    required=True
                ),
                openapi.Parameter(
                    name="food2-id",
                    in_=openapi.IN_QUERY,
                    type=openapi.TYPE_INTEGER,
                    required=True
                ),
                openapi.Parameter(
                    name="daily-meal",
                    in_=openapi.IN_QUERY,
                    type=openapi.TYPE_STRING,
                    required=True
                ),
                openapi.Parameter(
                    name="diet-id",
                    in_=openapi.IN_QUERY,
                    type=openapi.TYPE_INTEGER,
                    required=False
                ),
                openapi.Parameter(
                    name="dessert-id",
                    in_=openapi.IN_QUERY,
                    type=openapi.TYPE_INTEGER,
                    required=False
                ),

            ],
            responses={
                400:json.dumps({"error": "food-name or food-type or daily-meal is required."}),
                201:MealSerializer(many=False),
                306:json.dumps({"error":f"you have already create this meal and it's id is <meal id>"})
            }
    )
    def post(self,request:Request,*args,**kwargs):
        serializer=MealCreationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(data=serializer.data,status=status.HTTP_201_CREATED)
        return Response(data=serializer.errors,status=status.HTTP_400_BAD_REQUEST)
        

    @swagger_auto_schema(
            operation_description="get fields required for meal creation form",
            manual_parameters=[token],
            responses={
                200:CombinedFoodCreationSerializer
            }
    )
    def get(self,request:Request,*args,**kwargs):
        foods=Food.objects.exclude(Q(type="دسر") | Q( type="غذای رژیمی"))
        diets=Food.objects.filter(type="غذای رژیمی")
        desserts=Food.objects.filter(type="دسر")
        drinks=Drink.objects.all()
        foods_serialized=FoodSerializer(foods,many=True)
        diets_serialized=FoodSerializer(diets,many=True)
        desserts_serialized=FoodSerializer(desserts,many=True)
        drinks_serialized=DrinkSerializer(drinks,many=True)
        return Response(data={
            "foods":foods_serialized.data,
            "diets":diets_serialized.data,
            "desserts":desserts_serialized.data,
            "drinks":drinks_serialized.data  
        },status=status.HTTP_200_OK)
        # print(food_types)

@api_view(['DELETE'])
def delete_meal(request:Request,id:int):
    try:
        meal=Meal.objects.get(pk=id)
        meal.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    except Meal.DoesNotExist:
        return Response(status=status.HTTP_403_FORBIDDEN)
    

class ProfileAPIView(APIView):
    permission_classes=[IsUserOrReadOnly]
    @swagger_auto_schema(
            operation_description="get profile details",
            manual_parameters=[token],
            responses={
                200:UserSerializer
            }
    )
    def get(self,request:Request,*args,**kwargs):
        user=request.user
        serialized=UserSerializer(user,many=False)
        return Response(data=serialized.data,status=status.HTTP_200_OK)
    

    @swagger_auto_schema(
            operation_description="update profile details",
            manual_parameters=[token],
            request_body=UserSerializer,
            responses={
                200:UserSerializer,
                400:json.dumps({"error":"something"})
            }
    )
    def put(self,request:Request,*args,**kwargs):
        user=request.user
        user_data=request.data
        serializer=UserSerializer(user, data=user_data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

class FoodAPIView(APIView):
    permission_classes=[IsSupervisorOrReadOnly]

    @swagger_auto_schema(
            manual_parameters=[token],
            responses={
                200:FoodSerializer(many=True),
                403:json.dumps({"error":"don't have permission"})
            },
            operation_description="get all foods"
    )
    def get(self,request:Request,*args,**kwargs):
        foods=Food.objects.all()
        serializer=FoodSerializer(foods,many=True)
        return Response(data=serializer.data,status=status.HTTP_200_OK)
    
    @swagger_auto_schema(
            request_body=FoodSerializer(many=False),
            responses={
                201:FoodSerializer(many=False),
                400:json.dumps({"error":"something"}),
                403:json.dumps({"error":"don't have permission"})
            }
    )
    
    def post(self,request:Request,*args,**kwargs):
        serializer=FoodSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data,status=status.HTTP_201_CREATED)
        return Response(serializer.errors,status=status.HTTP_400_BAD_REQUEST)
    

@api_view(['GET'])
def send_test_email(request):
    try:
        send_mail(
            'Test Email',
            'test',
            'erfank20041382@gmail.com',
            ['erfank20041382@gmail.com'],
            fail_silently=False,
        )
        return HttpResponse("Test email sent.")
    except Exception as e:
        return HttpResponse(f"Failed to send email: {str(e)}")
    

def send_sms(request:Request):
    api = KavenegarAPI('4F6763536138714F4658476C764D534F6F5A2B48614F463173763364636670796B2B6F502B4371437473383D')
    params = { 'sender' : '10008663', 'receptor': '09335658101', 'message' :'.وب سرویس پیام کوتاه کاوه نگار' }
    response = api.sms_send( params)
    print(str(response))
    return JsonResponse(data=response[0])


def confirm_reset_password(request:Request,uid:str,token:str):
    return HttpResponse(f"works with {uid},{token}")


class PasswordResetRequestView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request: Request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            user = User.objects.get(email=email)
            code = get_random_string(6, allowed_chars='0123456789')
            user.reset_code = code
            user.save()

            # Render the HTML email template
            html_content = render_to_string('email/password_reset_email.html', {
                'user': user,
                'code': code,
            })

            subject = 'Password Reset Request'
            from_email = 'erfank20041382@gmail.com'
            to_email = email

            # Create an email message with both plain text and HTML content
            email_message = EmailMultiAlternatives(subject, '', from_email, [to_email])
            email_message.attach_alternative(html_content, "text/html")
            email_message.send()

            return Response({"detail": "Password reset e-mail has been sent."}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def check_code(request:Request):
    code = request.data.get('code')
    email = request.data.get('email')
    user=User.objects.get(email=email)
    if code==user.reset_code:
        return Response(status=status.HTTP_200_OK)
    return Response(status=status.HTTP_400_BAD_REQUEST)

class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request: Request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            new_password = serializer.validated_data['new_password']

            user = User.objects.get(email=email)
            user.set_password(new_password)
            user.reset_code = ''
            user.save()
            
            return Response({"detail": "Password has been reset."}, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

class FoodView(APIView):
    permission_classes=[permissions.IsAuthenticated,IsSupervisorOrReadOnly]
    def post(self,request:Request):
        serializer = FoodSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data,status=status.HTTP_201_CREATED)
        else:
            return Response(status=status.HTTP_400_BAD_REQUEST)
        

class ShiftManagerView(APIView):
    permission_classes=[permissions.IsAuthenticated,IsShiftManagerOrReadOnly]


    def get(self,request:Request):
        user=request.user
        shiftmanager=ShiftManager.objects.filter(user=user).first()
        shift=shiftmanager.shift
        shift_users=User.objects.filter(working_shift=shift).order_by('first_name','last_name')
        serializer=UserSerializer(shift_users,many=True)
        return Response(serializer.data,status=status.HTTP_200_OK)
    

    def post(self,request:Request):
        user_id=request.data.get("user",None)
        shiftmanager=ShiftManager.objects.filter(user=request.user).first()
        from_date=request.data.get("from_date",None)
        to_date=request.data.get("to_date",None)
        if not user_id or not shiftmanager or not from_date or not to_date:
            return Response(status=status.HTTP_400_BAD_REQUEST)
        from_date=ISO_to_gregorian(from_date)
        to_date=ISO_to_gregorian(to_date)
        user=User.objects.get(pk=user_id)
        supervisor_record=SupervisorRecord.objects.create(
            user=user,
            shift_manager=shiftmanager,
            from_date=from_date,
            to_date=to_date
        )
        serializer=SupervisorRecordSerializer(supervisor_record,many=False)
        return Response(data=serializer.data,status=status.HTTP_201_CREATED)
    

def filter_reservations(request_data:dict):
    user_search:str = request_data.get('user', '')
    shift_search:str = request_data.get('shift', '')
    date_search = request_data.get('date', None)
    # date_search=ISO_to_gregorian(date_search)
    # print(user_search,shift_search,date_search)
    reservations = Reservation.objects.filter(
        Q(user__first_name__icontains=user_search) |
        Q(user__last_name__icontains=user_search) |
        Q(user__username__icontains=user_search) | 
        Q(user__first_name__icontains=user_search.split()[0] if not (user_search.isspace() or user_search=='') else user_search) &
        Q(user__last_name__icontains=' '.join(user_search.split()[1:] if user_search!='' else user_search))
    ).filter(
        shift_meal__shift__shift_name=shift_search,
        shift_meal__date=date_search
    )
    return reservations


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated,IsSupervisorOrReadOnly])
def get_reservations_for_supervisor(request:Request):
        reservations=filter_reservations(request_data=request.data)
        reservations=reservations.order_by(Lower('user__first_name'),Lower('user__last_name'))
        serializer=SupervisorReservationSerializer(reservations,many=True,context={"request":request}).data
        return Response(data=serializer,status=status.HTTP_200_OK)  


class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


    def create(self, request:Request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except ValidationError as e:
            # print(e.detail)
            # response=e.detail
            # has_username_error=response.get('username')
            # has_email_error=response.get('email')
            # my_status=status.HTTP_400_BAD_REQUEST
            # if has_email_error and has_username_error:
            #     my_status=status.HTTP_302_FOUND
            # elif has_username_error:
            #     my_status=status.HTTP_303_SEE_OTHER
            # elif has_email_error:
            #     my_status=status.HTTP_306_RESERVED
            return Response(e.detail, status=status.HTTP_400_BAD_REQUEST)

        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    

class LoginView(generics.GenericAPIView):
    serializer_class = LoginSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data, status=status.HTTP_200_OK)
    

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated,IsSupervisorOrReadOnly])
def filter_shift_meals(request:Request):
    date=request.data.get('date')
    shift_name=request.data.get('shift')
    if not date or not shift_name:
        return Response(data={'error':"date or shift_name is required"},status=status.HTTP_400_BAD_REQUEST)
    shift_meals=ShiftMeal.objects.filter(date=ISO_to_gregorian(date),shift__shift_name=shift_name)
    serializer=ShiftMealSerializer(shift_meals,many=True,context={"request":request})
    return Response(serializer.data,status=status.HTTP_200_OK)



class UserUpdateAPIView(generics.RetrieveUpdateAPIView):
    serializer_class = UserUpdateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

    def put(self, request:Request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data,status=status.HTTP_200_OK)




    



    







