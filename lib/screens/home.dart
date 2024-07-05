import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:j_a_r_v_i_s/screens/consts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatUser _currentUser =
      ChatUser(id: '1', firstName: 'Dakshita', lastName: 'Thakkar');

  final ChatUser _gptChatUser =
      ChatUser(id: '2', firstName: 'J.A.R.V.I.S', lastName: '');
  final OpenAI openAI = OpenAI.instance.build(
      token: OPEN_AI_API_KEY
      ,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
      enableLog: true);
  String msg = '';
  String res = '';

  List<ChatMessage> messagesList = <ChatMessage>[];
  List<ChatUser> _typingUsers = <ChatUser>[];

  Future<void> generateResponse(ChatMessage message) async {
    print(message.text);

    setState(() {
      messagesList.insert(0, message);
      _typingUsers.add(_gptChatUser);
    });

    List<Map<String, dynamic>> messagesHistory =
        messagesList.reversed.map((message) {
      if (message.user == _currentUser) {
        return {
          'role': 'user',
          'content': message.text,
        };
      } else {
        return {
          'role': 'assistant',
          'content': message.text,
        };
      }
    }).toList();
    final request = ChatCompleteText(
        model: GptTurboChatModel(),
        messages: messagesHistory,
        maxToken: 200);

    try {
      final response = await openAI.onChatCompletion(request: request);

      for (var element in response!.choices) {
        if (element.message != null) {
          setState(() {
            messagesList.insert(
                0,
                ChatMessage(
                    user: _gptChatUser,
                    createdAt: DateTime.now(),
                    text: element.message!.content));
          });
        }
      }
    } catch (error) {
      // Handle the error more gracefully
      print('Error: $error');
      setState(() {
        messagesList.insert(
            0,
            ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: 'Error: $error'));
      });
    }
    setState(() {
      _typingUsers.remove(_gptChatUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(0, 166, 126, 1),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 30,
              width: 30,
              margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: CircleAvatar(child: Image.asset('assets/bot.png')),
            ),
            const SizedBox(
              width: 5,
            ),
            const Text('J.A.R.V.I.S',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ],
        ),
      ),
      body: DashChat(
          currentUser: _currentUser,
          typingUsers: _typingUsers,
          messageOptions: const MessageOptions(
              currentUserContainerColor: Colors.black,
              containerColor: Color.fromRGBO(0, 166, 126, 1),
              textColor: Colors.white),
          onSend: (ChatMessage message) {
            generateResponse(message);
          },
          messages: messagesList),
    );
  }
}
