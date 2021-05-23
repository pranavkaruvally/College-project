from django.contrib import auth
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import parser_classes
from rest_framework.parsers import FileUploadParser, MultiPartParser
from django.contrib.auth import get_user_model
from django.core.serializers import serialize
from django.db.models import Q
from chat.models import (
    Post,
    Comment,
    FriendRequest,
    Story
)
from .serializers import (
    PostSerializer,
    UserSerializer,
    UserProfileSerializer,
    UserCustomSerializer,
    PostDetailSerializer,
    UserStorySerializer,
)
import json

User = get_user_model()


@csrf_exempt
@api_view(['POST'])
def login(request):
    print(request.data)
    email = request.data["email"]
    password = request.data["password"]
    user = auth.authenticate(email=email, password=password)
    if user is not None:
        auth.login(request, user)
        serialized = UserSerializer(user)
        return Response(status=200, data=serialized.data)

    return Response(status=400, data={"email": email, "password": password})


@csrf_exempt
@api_view(['POST', 'PUT'])
@parser_classes([MultiPartParser])
def video_upload_handler(request):
    try:
        file_type = request.data['type']
        caption = request.data['caption']
        file = request.data['file']
        username = request.data['username']
        print(request.data)
        user = User.objects.get(username=username)
        post = Post.objects.create(
            post_type=file_type, caption=caption, file=file, user=user)
        post.save()
        return Response(status=200, data={"status": "success"})
    except:
        return Response(status=400, data={"status": "failure"})


@api_view(['GET'])
def get_user_list(request):
    try:
        param = request.query_params['name']
        print(param)
        qs = User.objects.filter(Q(username__icontains=param)
                                 | Q(f_name__icontains=param))
        # .filter(l_name__icontains=param)
        serialized = UserCustomSerializer(qs,many=True)
        print(request.query_params)
        # print(data)
        return Response(status=200, data=serialized.data)
    except Exception as e:
        print(e)
        return Response(status=400)


@api_view(['GET'])
def get_posts(request, username):
    try:
        user = User.objects.get(username=username)
        qs = Post.objects.order_by("-id")[:10]
        serialized = PostSerializer(qs, many=True, context={"user": user})
        print(serialized.data)
        return Response(status=200, data=serialized.data)
    except Exception as e:
        print(e)
        return Response(status=400)

@api_view(['GET'])
def get_previous_posts(request,username):
    try:
        user = User.objects.get(username=username)
        id=request.query_params['id']
        qs = Post.objects.filter(id__lt=int(id)).order_by('-id')[:5]
        print(qs)
        serialized = PostSerializer(qs, many=True, context={"user": user})
        print(serialized.data)
        return Response(status=200, data=serialized.data)
    except Exception as e:
        print(e)
        return Response(status=400)


@api_view(['GET'])
def get_profile_and_posts(request, id):
    try:
        user = User.objects.get(id=id)
        cur_user = User.objects.get(username=request.query_params['username'])
        friend_request = FriendRequest.objects.filter(
            from_user=cur_user, to_user=user)
        print(friend_request)
        serialized = UserProfileSerializer(
            user, context={"request": friend_request,'cur_user':cur_user})
        print(serialized.data)
        return Response(status=200, data=serialized.data)
    except Exception as e:
        print(e)
        return Response(status=400)


@api_view(['GET'])
def get_comments(request, id):
    try:
        post = Post.objects.get(id=id)
        serialized = PostDetailSerializer(post)
        return Response(status=200, data=serialized.data)
    except Exception as e:
        print(e)
        return Response(status=400)


@api_view(['POST'])
def add_comment(request, username):
    try:
        print(request.data['comment'])
        print(json.dumps(request.data['comment']).__class__)
        print(request.data['mentions'])
        print(request.data['mentions'].__class__)
        user = User.objects.get(username=username)
        post = Post.objects.get(id=request.data['post'])
        comment = Comment.objects.create(
            user=user, post=post, comment=json.dumps(request.data['comment']))
        for i in request.data['mentions']:
            comment.mentions.add(User.objects.get(username=i))

        comment.save()
        context = {
            'id': comment.id
        }

        return Response(status=200, data=context)
    except Exception as e:
        print(e)
        return Response(status=400)


@api_view(["GET"])
def like_post(request):
    try:
        username = request.query_params['username']
        post_id = request.query_params['id']
        user = User.objects.get(username=username)
        post = Post.objects.get(id=post_id)
        post.likes.add(user)
        post.save()
        return Response(status=200)
    except:
        return Response(status=400)


@api_view(["GET"])
def dislike_post(request):
    try:
        username = request.query_params['username']
        post_id = request.query_params['id']
        user = User.objects.get(username=username)
        post = Post.objects.get(id=post_id)
        post.likes.remove(user)
        post.save()
        return Response(status=200)
    except:
        return Response(status=400)


@api_view(['GET'])
def send_friend_request(request):
    try:
        username = request.query_params['username']
        from_user = User.objects.get(username=username)
        print(request.query_params['id'])
        to_user = User.objects.get(id=request.query_params['id'])
        friend_request = FriendRequest.objects.create(
            from_user=from_user,
            to_user=to_user, 
            status="pending",
            )
        friend_request.save()
        return Response(status=200)
    except Exception as e:
        print(e)
        return Response(status=400)


@api_view(['GET'])
def handle_friend_request(request):
    try:
        id = int(request.query_params['id'])        
        action = request.query_params['action']
        frnd_rqst= FriendRequest.objects.get(id=id)
        from_user = frnd_rqst.from_user
        to_user = frnd_rqst.to_user
        if action=="accept":       
            frnd_rqst.status = "accepted"
            from_user.profile.friends.add(to_user)
            to_user.profile.friends.add(from_user)
            frnd_rqst.delete()
        elif action=="reject":
            frnd_rqst.status = "rejected"
            frnd_rqst.delete()
        return Response(status=200)
    except Exception as e:
        print(e)
        return Response(status=400)



@api_view(['GET'])
def get_stories(request):
    try:
        qs = User.objects.all()
        serialized = UserStorySerializer(qs, many=True)
        print(serialized.data)
        newList = [i for i in serialized.data if i is not None]
        print(newList)
        return Response(status=200, data=newList)
    except Exception as e:
        print(e)
        return Response(status=400)



@csrf_exempt
@api_view(['POST', 'PUT'])
@parser_classes([MultiPartParser])
def story_upload_handler(request):
    try:
        file = request.data['file']
        username = request.data['username']
        print(request.data)
        user = User.objects.get(username=username)
        story = Story.objects.create(file=file, user=user)
        story.save()
        return Response(status=200)
    except:
        return Response(status=400)


@api_view(['GET'])
def get_status(request):
    try:
        username = request.query_params['username']
        cur_id = request.query_params['id']
        cur_user = User.objects.get(id=int(cur_id))
        user = User.objects.get(username=username)
        user.profile.people_i_should_inform.add(cur_user)
        user.save()
        cur_user.profile.people_i_peek.add(user)
        cur_user.save()
        if(user.profile.online):
            return Response(status=200,data={"status":"online"})
        else:
            return Response(status=200,data={"status":user.profile.last_seen.strftime("%Y-%m-%d %H:%M:%S")})
    except Exception as e:
        print(e)
        return Response(status=400)

@api_view(['GET'])
def ping(request):
    return Response(status=200)


@api_view(['GET'])
def user_story_viewed(request):
    try:
        story_id = request.query_params['id']
        user_id = request.query_params['u_id']
        story = Story.objects.get(id=int(story_id))
        user = User.objects.get(id=user_id)
        story.views.add(user)
        story.save()
        return Response(status=200)

    except Exception as e:
        print(e)
        return Response(status=400)