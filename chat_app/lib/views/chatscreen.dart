import 'package:flutter/material.dart';
import 'package:chat_app/helperFunctions/sharedpref_helper.dart';
import 'package:random_string/random_string.dart';
import 'package:chat_app/services/database.dart';

// import firebase
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatWithUsername, name;
  ChatScreen(this.chatWithUsername, this.name);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  String chatRoomId, messageId = "";
  String myName, myProfilePic, myUserName, myEmail;
  Stream messageStream;
  TextEditingController messageTextEditingController = TextEditingController();

  getMyInfoFromSharedPreference() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail= await SharedPreferenceHelper().getUserEmail();

    chatRoomId = getChatRoomIdByUsernames(widget.chatWithUsername, myUserName);
  }

  getChatRoomIdByUsernames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    }
    else {
      return "$a\_$b";
    }
  }

  addMessage(bool sendClicked) {
    if(messageTextEditingController != "") {
      String message = messageTextEditingController.text;

      var lastMessageTs = DateTime.now();

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy" : myUserName,
        "ts" : lastMessageTs,
        "imgUrl" : myProfilePic,
      };

      // messageId
      if (messageId == "") {
        messageId = randomAlphaNumeric(12);
      }

      DatabaseMethods().addMessage(chatRoomId, messageId, messageInfoMap)
      .then((value) {
        
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage" : message,
          "lastMessageSendTs" : lastMessageTs,
          "lastMessageSendBy" : myUserName
        };

        DatabaseMethods().updateLastMessageSend(chatRoomId, lastMessageInfoMap);

        if(sendClicked) {
          // remove the text in the message input field
          messageTextEditingController.text = "";

          // make message id blank to get regenerated on next message send
          messageId = "";
        }
      });
    }
  }

  Widget chatMessageTile(String message, bool sendByMe) {
    return Row(
      mainAxisAlignment: sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), 
              bottomRight: sendByMe ? Radius.circular(0) : Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: sendByMe ? Radius.circular(24) : Radius.circular(0),
            ), 
            color: Colors.blue
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.all(16),
          child: Text(message, style: TextStyle(color: Colors.white)),

        ),
      ],
    );
  }

  Widget chatMessages() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, snapshot) {
        return snapshot.hasData ? ListView.builder(
          padding: EdgeInsets.only(bottom: 120, top: 16),
          reverse: true,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            return chatMessageTile(ds["message"], myUserName == ds["sendBy"]);
          },
        )
        :
        Center(child: CircularProgressIndicator());
      },
    );
  }

  getAndSetMessages() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPreference();
    getAndSetMessages();
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Container(
        child: Stack(
          children: [
            chatMessages(),
            Container(
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.only(bottom: 32),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.black.withOpacity(0.8),
                ),
                child: Row(
                  children: [
                    Expanded(child: TextField(
                      onChanged: (value) {
                        addMessage(false);
                      },
                      controller: messageTextEditingController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none, 
                        hintText: "Type your message...",
                        hintStyle: TextStyle(fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.6)))
                    )),
                    GestureDetector(
                      onTap: () {
                        addMessage(true);
                      },
                      child: Icon(Icons.send, color: Colors.white)
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}