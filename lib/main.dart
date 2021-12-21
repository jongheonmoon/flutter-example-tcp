import 'package:flutter/material.dart';
import 'package:tcptest/network/TCPManager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const SocketClient(),
    );
  }
}

class SocketClient extends StatefulWidget {
  const SocketClient({Key? key}) : super(key: key);

  @override
  SocketClientState createState() => SocketClientState();
}

class SocketClientState extends State<SocketClient> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String localIP = "lacalIP";
  List<MessageItem> items = <MessageItem>[];

  TextEditingController msgCon = TextEditingController();

  @override
  void initState() {
    super.initState();
    getIP();
  }

  @override
  void dispose() {
    TCPManager.disconnectFromServer();
    super.dispose();
  }

  void getIP() async {
    var ip = 'local';
    setState(() {
      localIP = ip;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(title: const Text("Socket Client")),
        body: Column(
          children: <Widget>[
            messageListArea(),
            submitArea(),
          ],
        ));
  }

  Widget ipInfoArea() {
    return Card(
      child: ListTile(
        dense: true,
        leading: const Text("IP"),
        title: Text(localIP),
      ),
    );
  }

  Widget messageListArea() {
    return Expanded(
      child: ListView.builder(
          reverse: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            MessageItem item = items[index];
            return Container(
              alignment: (item.owner == localIP) ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: (item.owner == localIP) ? Colors.blue[100] : Colors.grey[200]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      (item.owner == localIP) ? "Client" : "Server",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.content,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget submitArea() {
    return Card(
      child: ListTile(
        title: TextField(
          controller: msgCon,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.send),
          color: Colors.blue,
          disabledColor: Colors.grey,
          onPressed: submitMessage,
        ),
      ),
    );
  }

  void submitMessage() async {
    if (msgCon.text.isEmpty) {
      showSnackBarWithKey("message isEmpty");
      return;
    }

    if (await TCPManager.sendPackets(
        msgCon.text,
        TCPListener((success) {
          setState(() {
            items.insert(0, MessageItem("test", success));
          });
        }, (fail) {
          showSnackBarWithKey(fail);
        }))) {
      setState(() {
        items.insert(0, MessageItem(localIP, msgCon.text));
      });
      msgCon.clear();
    } else {
      showSnackBarWithKey("전송 실패");
    }
  }

  showSnackBarWithKey(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
      action: SnackBarAction(
        label: 'Done',
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar;
        },
      ),
    ));
  }
}

class MessageItem {
  String? owner;
  String content;

  MessageItem(this.owner, this.content);
}
