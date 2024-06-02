from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework import status
from rest_framework import permissions
from .serializers import MealSerializer,ShiftMealSerializer,WorkFlowSerializer,ShiftSerializer,FoodSerializer,CombinedMealShiftSerializer,CombinedFoodCreationSerializer
from rest_framework.decorators import api_view,permission_classes
from .models import ShiftMeal,Meal,WorkFlow,Shift,Food,FoodType,DailyMeal
import jdatetime
from rest_framework.views import APIView
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from .swagger_helper import token
import json
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken


def ISO_to_gregorian(date:str):
    jalali_date = jdatetime.date.fromisoformat(date)
    gregorian_date = jalali_date.togregorian()  
    return gregorian_date



        

@swagger_auto_schema(
    method="POST",
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
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def filter_meals(request:Request):
    filters={}
    date = request.data.get('date')
    shift_name = request.data.get('shift')
    food1_name=request.data.get('food1-name')
    food2_name=request.data.get('food2-name')
    food_type=request.data.get('food-type')
    daily_meal=request.data.get('daily-meal')
    if date:
        gregorian_date=ISO_to_gregorian(date)
        filters["date"]=gregorian_date
    if shift_name:
        filters["shift__shift_name"]=shift_name
    if food1_name:
        filters["meal__food1__name"]=food1_name
    if food2_name:
        filters["meal__food2__name"]=food2_name
    if food_type:
        filters["meal__food_type"]=food_type
    if daily_meal:
        filters["meal__daily_meal"]=daily_meal
    meals = ShiftMeal.objects.filter(**filters)
    # meals=ShiftMeal.objects.filter(shift__shift_name=shift_name)
    serialized=ShiftMealSerializer(meals,many=True)
    return Response(serialized.data,status=status.HTTP_200_OK)

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
def get_all_reservations(requrest:Request):
    my_user=requrest.user
    shift_meals=ShiftMeal.objects.filter(shift__work_flows__user=my_user)
    serialized=ShiftMealSerializer(shift_meals,many=True)
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
            201:WorkFlowSerializer(many=False),
            306:"{'error'':'already reserved'}",
            410:"{'error':'shift meal doesn't exist'}"
        }
)
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def reserve_meal(request:Request):
    shift_meal_id:dict = request.data.get('shift-meal-id')
    try:
        shift_meal:ShiftMeal=ShiftMeal.objects.get(id=shift_meal_id)
        shift=shift_meal.shift
        work_flow,created=WorkFlow.objects.get_or_create(shift=shift,shift__shift_meals=shift_meal,user=request.user)
        if not created:
            return Response(data={"error":"you have already reserve this shift meal"},status=status.HTTP_306_RESERVED)
        serialized=WorkFlowSerializer(work_flow,many=False)
        return Response(data=serialized.data,status=status.HTTP_201_CREATED)

    except ShiftMeal.DoesNotExist:
        return Response(data={"error":f"no shift meal with id {shift_meal_id}"},status=status.HTTP_410_GONE)




class ShiftMealAPIView(APIView):
    permission_classes=[permissions.IsAuthenticated]

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
        meal_id=request.data.get('meal-id') 
        if not shift_name or not date or not meal_id:
            return Response({"error": "shift or date or meal is required."}, status=status.HTTP_400_BAD_REQUEST)
        try:
            shift,created=Shift.objects.get_or_create(shift_name=shift_name)
            meal=Meal.objects.get(id=meal_id)
            shift_meal,created=ShiftMeal.objects.get_or_create(shift=shift,date=ISO_to_gregorian(date),meal=meal)
            if not created:
                return Response(data={"error":"you have already create this shift meal"},status=status.HTTP_306_RESERVED)
            serialized=ShiftMealSerializer(shift_meal,many=False)
            return Response(data=serialized.data,status=status.HTTP_201_CREATED)
        except Meal.DoesNotExist:
            return Response(data={"error":f"there no existing meal with id {meal_id}"},status=status.HTTP_204_NO_CONTENT)
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
    def post(self,request:Request,*args,**kwargs):
        pass

    @swagger_auto_schema(
            operation_description="get fields required for meal creation form",
            manual_parameters=[token],
            responses={
                200:CombinedFoodCreationSerializer
            }
    )
    def get(self,request:Request,*args,**kwargs):
        foods=Food.objects.all()
        food_types=[food_type.label for food_type in FoodType]
        daily_meals=[daily_meal.label for daily_meal in DailyMeal]
        foods_serialized=FoodSerializer(foods,many=True)
        return Response(data={
            "foods":foods_serialized.data,
            "food_types":food_types,
            "daily_meals":daily_meals  
        },status=status.HTTP_200_OK)
        # print(food_types)


    







