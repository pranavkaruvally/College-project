import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .models import Thread,Profile,ChatMessage
from django.utils import timezone
from django.contrib.auth import get_user_model
from datetime import datetime

User = get_user_model()

# Right now we need two chat consumers.
# One to be used in production and the other one in development for testing and debugging.
# The primary difference between the two is that the latter does require authentication. 



# Consumers are written in such a way that the component functions are arranged in the order in which
# they are triggered. 
# ie 'connect' -> 'receive' -> 'chat_message' -> 'disconnect'
# The database operations performed by each function are given next to it. For the sake of comprehension and readability.


# ===========================================
# Consumer; strictly for use in production
# ===========================================
class DevelopmentChatConsumer(AsyncWebsocketConsumer):

    room_group_name = "chat_room"

    async def connect(self):

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()
        

    async def receive(self,text_data):
        
        print("In receive" , text_data)
        json_data = json.loads(text_data)
        
        # Sending to all users in the group/room
        await self.channel_layer.group_send(
            self.room_group_name,{    
            'type':'chat_message',
            'message':json_data
        })

    async def chat_message(self,event):
        
        print("In chat_message", event)
        event['message']['time'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Converting the json object to a string
        message = json.dumps({                  
            'message':event['message']
        })

        # Sending to the connected user
        await self.send(text_data = message)

    async def disconnect(self,close_code):
        
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )



# =====================================
# Consumer: For production
# =====================================
class ChatConsumer(AsyncWebsocketConsumer):

    room_group_name = 'common_room'

    async def connect(self):        
        self.user = self.scope['user']
        await self.update_user_online(self.user)

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

        pending_messages = await self.get_pending_messages()

        if len(pending_messages)!=0:
            for msg in pending_messages:
                text,snd_user,chat_id = await self.get_chat_details(msg)
                
                msg_obj = json.dumps({
                    'message':text,
                    'from':snd_user,
                    'id':chat_id
                })

                await self.send(text_data=msg_obj)

    @database_sync_to_async
    def update_user_online(self, user):
        Profile.objects.filter(user=user).update(online=True)

    @database_sync_to_async
    def get_pending_messages(self):

        threads = []
        # Get all the threads in which the user is a member
        for thread in Thread.objects.all():
            if self.user == thread.first or self.user == thread.second:
                threads.append(thread)

        chat_messages = []
        # Checking each thread for unread chat messages for user and appending those to the corresponding list
        if len(threads)!=0:
            for thread in threads:
                for chat in thread.chatmessage_set.all():
                    if self.user not in chat.recipients.all():
                        chat_messages.append(chat)

        return chat_messages


    @database_sync_to_async
    def get_chat_details(self, chat_message):
        return chat_message.message, chat_message.user.username, chat_message.id



    async def receive(self, text_data):

        text_data_json = json.loads(text_data)
        print(text_data_json)
        if 'received' in text_data_json['message']:
            msg_id = int(text_data_json['message']['received'])
            await self.add_user_to_recipients(msg_id)

        else:
            to = text_data_json['to']           # This is the username of the user to which the message is to be sent
            msg = text_data_json['message']

            chat_msg_id = await self.create_chat_message(message=msg,to=to)
            
            message = {
                'message':msg,
                'to':to,
                'id':chat_msg_id,
                'from':self.user.username  # This line is not needed in production; only for debugging
            }

            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type':'chat_message',
                    'message': message
                }
            )


    @database_sync_to_async
    def add_user_to_recipients(self,msg_id):
        chat_msg = ChatMessage.objects.get(id=msg_id)
        chat_msg.recipients.add(self.user)
        chat_msg.save()

    @database_sync_to_async
    def create_chat_message(self, message, to):
        thread = Thread.objects.get_or_new(self.user,to)
        cur_message = ChatMessage.objects.create(user=self.user, message=message, thread=thread)
        cur_message.save()
        return cur_message.id

    
    async def chat_message(self,event):

        to_username = event['message']['to']
        from_username = event['message']['from']

        to_user_obj = await self.get_user_from_username(to_username)
        from_user_obj = await self.get_user_from_username(from_username)

        if self.user == to_user_obj or self.user == from_user_obj:
            json_data = json.dumps(event['message'])
            await self.send(text_data=json_data)


    @database_sync_to_async
    def get_user_from_username(self, username):
        return User.objects.get(username=username)

    
    async def disconnect(self, close_code):
        await self.update_user_offline(self.user)

    @database_sync_to_async
    def update_user_offline(self, user):
        Profile.objects.filter(user=user).update(online=False)




