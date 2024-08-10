from rest_framework.serializers import ModelSerializer
from .models import Meal,ShiftMeal,Shift,Reservation,User,Food,FoodType,DailyMeal,Drink,User,SupervisorRecord,ShiftManager
from rest_framework import serializers
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_decode
from django.utils.encoding import force_str
# from django.contrib.auth.models import User
from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from datetime import datetime
from datetime import timedelta
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'profile', 'working_shift', 'first_name', 'last_name']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    email = serializers.EmailField(
        error_messages={
            'invalid': 'یک ایمیل معتبر وارد کنید',
            'unique':'ایمیل وارد شده قبلاً استفاده شده است'
        }
    )
    username=serializers.CharField(
        error_messages={
            'unique':'یوزرنیم تکراری است',
            # 'invalid':'یوزرنیم تکراری است' 
        }
    )

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'first_name', 'last_name']


    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('یوزرنیم تکراری است')
        return value

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("ایمیل تکراری میباشد")
        return value

    def validate_password(self, value):
        if len(value) < 8:
            raise serializers.ValidationError("پسورد باید حداقل 8 کاراکتر باشد")
        if not any(char.isdigit() for char in value):
            raise serializers.ValidationError("پسورد باید حداقل یک عدد داشته باشد")
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)
    access = serializers.CharField(read_only=True)
    refresh = serializers.CharField(read_only=True)

    def validate(self, data):
        username = data.get("username")
        password = data.get("password")

        if username and password:
            user = authenticate(username=username, password=password)

            if user:
                if not user.is_active:
                    raise serializers.ValidationError("User is deactivated.")
                
                refresh = RefreshToken.for_user(user)
                return {
                    'access': str(refresh.access_token),
                    'refresh':str(refresh)
                }
            else:
                raise serializers.ValidationError("Unable to log in with provided credentials.")
        else:
            raise serializers.ValidationError("Must include 'username' and 'password'.")

class FoodSerializer(ModelSerializer):
    class Meta:
        model = Food
        fields="__all__"


class DrinkSerializer(serializers.ModelSerializer):
    class Meta:
        model =Drink
        fields = "__all__"


class MealSerializer(ModelSerializer):
    food=FoodSerializer(many=False)
    diet=FoodSerializer(many=False)
    dessert=FoodSerializer(many=False)
    drinks=DrinkSerializer(many=True)
    class Meta:
        model = Meal
        fields=('id','food','diet','dessert','daily_meal','drinks')

    # def to_internal_value(self, data):
    #     # Convert ID fields to instances for internal use
    #     internal_value = super().to_internal_value(data)
    #     food_id = data.get('food')
    #     diet_id = data.get('diet')
    #     dessert_id = data.get('dessert')
    #     drink_ids = data.get('drinks', [])

    #     if food_id:
    #         internal_value['food'] = Food.objects.get(id=food_id)
    #     if diet_id:
    #         internal_value['diet'] = Food.objects.get(id=diet_id)
    #     if dessert_id:
    #         internal_value['dessert'] = Food.objects.get(id=dessert_id)
    #     if drink_ids:
    #         internal_value['drinks'] = Drink.objects.filter(id__in=drink_ids)

    #     return internal_value

    # def create(self, validated_data):
    #     drinks_data = validated_data.pop('drinks', [])
    #     meal = Meal.objects.create(**validated_data)
    #     meal.drinks.set(drinks_data)
    #     return meal

    # def to_representation(self, instance):
    #     # Use nested serializers for output
    #     representation = super().to_representation(instance)
    #     representation['food'] = FoodSerializer(instance.food).data
    #     representation['diet'] = FoodSerializer(instance.diet).data if instance.diet else None
    #     representation['dessert'] = FoodSerializer(instance.dessert).data if instance.dessert else None
    #     representation['drinks'] = DrinkSerializer(instance.drinks.all(), many=True).data
    #     return representation



class ShiftSerializer(ModelSerializer):
    class Meta:
        model = Shift
        fields="__all__"


class ShiftMealSerializer(ModelSerializer):
    meal=MealSerializer(many=False)
    shift=ShiftSerializer(many=False)
    is_reserved=serializers.SerializerMethodField()
    class Meta:
        model = ShiftMeal
        fields=('id','meal','shift','date','is_reserved')

    def get_is_reserved(self,obj:ShiftMeal):
        return Reservation.objects.filter(shift_meal=obj,user=self.context["request"].user).exists() and (obj.date > datetime.now())

class UserSerializer(ModelSerializer):
    class Meta:
        model = User
        fields=('id','username','email','profile','is_supervisor',"is_shift_manager","working_shift",'first_name',
                'last_name')
        ref_name="UserSerializer"


class ReservationSerializer(ModelSerializer):
    shift_meal=ShiftMealSerializer(many=False)
    user=UserSerializer(many=False)
    class Meta:
        model = Reservation
        fields=('id','user','shift_meal','date')

        def to_representation(self, instance:Reservation):
            # Get the representation of the reservation instance
            representation = super().to_representation(instance)
            
            # Re-serialize the shift_meal field with context
            shift_meal_serializer = ShiftMealSerializer(instance.shift_meal, context=self.context)
            representation['shift_meal'] = shift_meal_serializer.data
            
            return representation





    

class CombinedMealShiftSerializer(serializers.Serializer):
    meals = MealSerializer(many=True)
    shifts = ShiftMealSerializer(many=True)



class CombinedFoodCreationSerializer(serializers.Serializer):
    foods=FoodSerializer(many=True)
    food_types = serializers.ListField(
        child=serializers.CharField(), 
        default=[food_type.label for food_type in FoodType]
    )
    daily_meals = serializers.ListField(
        child=serializers.CharField(),
        default=[daily_meal.label for daily_meal in DailyMeal]
    )




class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        if not User.objects.filter(email=value).exists():
            raise ValidationError("This email address is not registered.")
        return value

class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    new_password = serializers.CharField(min_length=8, write_only=True)

    def validate_email(self, value):
        """
        Check if the email exists in the database.
        """
        if not User.objects.filter(email=value).exists():
            raise serializers.ValidationError("This email is not registered.")
        return value

    def validate_new_password(self, value:str):
        """
        Check if the new password meets the criteria.
        """
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters long.")
        if not any(char.isdigit() for char in value):
            raise serializers.ValidationError("Password must contain at least one digit.")
        # Add other password validations if needed (e.g., complexity, special characters)
        return value

    def validate(self, data):
        """
        Check if the code is correct for the provided email.
        """
        email = data.get('email')

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise serializers.ValidationError("Invalid email or code.")
        
        return data
    




class MealCreationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Meal
        fields =('food','drinks','dessert','diet','daily_meal')

    def validate(self, data:dict):
        food = data.get('food')
        diet = data.get('diet')
        dessert = data.get('dessert')
        daily_meal = data.get('daily_meal')
        drinks = data.get('drinks')

        # Check for existing meal with the same details
        existing_meal = Meal.objects.filter(
            food=food,
            diet=diet,
            dessert=dessert,
            daily_meal=daily_meal,
        ).distinct()

        # Further filtering with drinks as it's a many-to-many field
        if existing_meal.exists():
            existing_meal = existing_meal.filter(drinks__in=drinks)
            if existing_meal.exists():
                raise serializers.ValidationError("A meal with these details already exists.")

        return data

    def create(self, validated_data):
        drinks = validated_data.pop('drinks')
        meal = Meal.objects.create(**validated_data)
        meal.drinks.set(drinks)
        return meal


class ShiftManagerSerializer(serializers.ModelSerializer):
    user=UserSerializer(many=False)
    shift=ShiftSerializer(many=False)
    class Meta:
        model = ShiftManager
        fields =('id','user','shift')



class SupervisorRecordSerializer(serializers.ModelSerializer):
    user=UserSerializer(many=False)
    shift_manager=ShiftManagerSerializer(many=False)
    class Meta:
        model = SupervisorRecord
        fields =('id','user','shift_manager','from_date','to_date')


class SupervisorRecordCreationSerializer(serializers.ModelSerializer):
    class Meta:
        model=SupervisorRecord
        fields = ('user','shift_manager','from_date','to_date')

class SupervisorReservationSerializer(serializers.ModelSerializer):
    user = UserSerializer()
    lunch = serializers.SerializerMethodField()
    dinner = serializers.SerializerMethodField()
    date = serializers.DateField(format="%Y-%m-%d")

    class Meta:
        model = Reservation
        fields = ['id', 'user', 'lunch', 'dinner', 'date']
        
    def get_lunch(self, obj:Reservation):
        shift_meal_query_set=ShiftMeal.objects.filter(reservations=obj,meal__daily_meal="ناهار")
        if shift_meal_query_set.exists():
            return ShiftMealSerializer(shift_meal_query_set.first(),many=False,context=self.context).data
        return None

    def get_dinner(self, obj:Reservation):
        shift_meal_query_set=ShiftMeal.objects.filter(reservations=obj,meal__daily_meal="شام")
        if shift_meal_query_set.exists():
            return ShiftMealSerializer(shift_meal_query_set.first(),many=False,context=self.context).data
        return None
    


class UserUpdateSerializer(serializers.ModelSerializer):
    profile = serializers.ImageField(required=False)
    class Meta:
        model = User
        fields = ['username', 'profile', 'email', 'first_name', 'last_name']
    
    def validate_email(self,value:str):
        if User.objects.filter(email=value).exclude(self.instance).exists():
            raise serializers.ValidationError("email is already exists")
        return value


    


    






