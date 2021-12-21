// ignore_for_file: file_names, avoid_print

import 'dart:async';
import 'dart:collection';
import 'dart:io';

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
  static int port = 1004;
  static String serverIp = "192.168.0.110";
  static Socket? clientSocket;
  static bool isConnect = false;
  static HashMap<int, TCPListener> hashMap = HashMap();
  static int getCount = 0;

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
  // 0 은 임시 키값 나중에 키를 바꿔야함
  static _responsePacket() async {
    clientSocket?.listen(
      (onData) {
        print("responsePacket: ${String.fromCharCodes(onData).trim()}");
        hashMap[0]?.success(String.fromCharCodes(onData).trim());
        hashMap.removeWhere((key, value) => key == 0);
      },
      onDone: onDone,
      onError: onError,
    );
  }

  // 0 은 임시 키값 나중에 키를 바꿔야함
  static Future<bool> sendPackets(String message, TCPListener tcpListener) async {
    try {
      if (isConnect) {
        clientSocket?.write("$message\n");
        print("sendMessage: $message");
        hashMap.update(0, (value) => tcpListener, ifAbsent: () => tcpListener);
        return true;
      } else {
        if (await connectToServer()) {
          clientSocket?.write("$message\n");
          print("sendMessage: $message");
          hashMap.update(0, (value) => tcpListener, ifAbsent: () => tcpListener);
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
    hashMap[0]?.fail("onDone");
    disconnectFromServer();
  }

  static void onError(e) {
    print("onError: $e");
    hashMap[0]?.fail("onError: $e");
    disconnectFromServer();
  }

  static void disconnectFromServer() {
    print("disconnectFromServer");
    isConnect = false;
    clientSocket?.close();
    clientSocket = null;
  }
}
