# middleware.py
from django.conf import settings
from django.http import JsonResponse,HttpRequest

class ValidateAppTokenMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request:HttpRequest):
        if request.path.startswith('/api/password/reset/') or request.path.startswith('/api/register/') or request.path.startswith('/api/check-code/'):
            token = request.headers.get('App-Token')
            if token != settings.UNIQUE_APP_TOKEN:
                return JsonResponse({'detail': 'Invalid token'}, status=403)
        return self.get_response(request)
