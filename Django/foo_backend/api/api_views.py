from django.contrib import auth
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import parser_classes
from rest_framework.parsers import FileUploadParser,MultiPartParser

@csrf_exempt
@api_view(['POST'])
def login(request):
	print(request.data)
	email = request.data['email']
	password = request.data["password"]
	user = auth.authenticate(email=email,password=password)
	if user is not None:
		auth.login(request,user)
		return Response(status=200,data={'status':"you are in"})
	
	return Response(status=400,data={"email":email,"password":password})

@csrf_exempt
@api_view(['POST','PUT'])
@parser_classes([MultiPartParser])
def audio_upload_handler(request):
	# print('files',request.FILES)
	print('data',request.data)
	print(request.data['name'])
	return Response(status=400,data={"status":"success"})