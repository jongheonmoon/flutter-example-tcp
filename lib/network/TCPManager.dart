// ignore_for_file: file_names, avoid_print

import 'dart:async';
import 'dart:collection';
import 'dart:io';

// Listener interface
class TCPListener {
  final Function(String) _success;
  final Function(String) _fail;

  TCPListener(this._success, this._fail);

  success(String response) {
    _success.call(response);
  }

  fail(String msg) {
    _fail.call(msg);
  }
}

class TCPManager {
  static int port = 1004; // Server Port
  static String serverIp = "192.168.0.110"; // Server IP
  static Socket? clientSocket;
  static bool isConnect = false; // Server Connect bool
  static HashMap<int, TCPListener> hashMap = HashMap(); //interface HashMap
  static int callSeq = 0; // callSeq (unique key)

  static Future<bool> connectToServer() async {
    return Socket.connect(serverIp, port, timeout: const Duration(seconds: 5)).then((socket) {
      clientSocket = socket;
      print("Connected to ${socket.remoteAddress.address}:${socket.remotePort}");
      isConnect = true;
      _responsePacket();
      return true;
    }).catchError((e) {
      print(e.toString());
      isConnect = false;
      return false;
    });
  }

  // callSeq 은 임시 키값 나중에 키를 바꿔야함
  static _responsePacket() async {
    clientSocket?.listen(
      (onData) {
        print("responsePacket: ${String.fromCharCodes(onData).trim()}");
        hashMap[callSeq]?.success(String.fromCharCodes(onData).trim());
        hashMap.removeWhere((key, value) => key == callSeq);
      },
      onDone: onDone,
      onError: onError,
    );
  }

  // callSeq 은 임시 키값 나중에 키를 바꿔야함
  static Future<bool> sendPackets(String message, TCPListener tcpListener) async {
    try {
      if (isConnect) {
        clientSocket?.write("$message\n");
        print("sendMessage: $message");
        hashMap.update(callSeq, (value) => tcpListener, ifAbsent: () => tcpListener);
        return true;
      } else {
        if (await connectToServer()) {
          clientSocket?.write("$message\n");
          print("sendMessage: $message");
          hashMap.update(callSeq, (value) => tcpListener, ifAbsent: () => tcpListener);
          return true;
        } else {
          return false;
        }
      }
    } catch (e) {
      return false;
    }
  }

  static void onDone() {
    print("onDone");
    hashMap[callSeq]?.fail("onDone");
    hashMap.removeWhere((key, value) => key == callSeq);
    disconnectFromServer();
  }

  static void onError(e) {
    print("onError: $e");
    hashMap[callSeq]?.fail("onError: $e");
    hashMap.removeWhere((key, value) => key == callSeq);
    disconnectFromServer();
  }

  static void disconnectFromServer() {
    print("disconnectFromServer");
    isConnect = false;
    clientSocket?.close();
    clientSocket = null;
  }
}
