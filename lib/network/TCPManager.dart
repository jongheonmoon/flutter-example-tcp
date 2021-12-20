import 'dart:async';
import 'dart:io';

class TCPListener {
  void onSuccess(String str) {}
  void onFail(String str) {}
}

class TCPManager {

  static final TCPManager _instance = TCPManager._internal();
  factory TCPManager() => _instance;

  Socket? _socket;
  int _tcpCount = 0;

  final Map<int, Function> _syncHashMap = {};

  TCPManager._internal() {
  }

  void setTCPListener(String param, Function listener) {
    int nCallSeq = _getTcpCount();
    _syncHashMap[nCallSeq] = listener;

    _sendPackets(nCallSeq, Packet(param));
  }

  void _sendPackets(int callSeq, Packet packet) {
    _serverConnect().then((val) {
      if (!val) {
        _sendFail(callSeq, "서버와의 연결이 실패 하였습니다.");
        return;
      }

      try {
        if (_socket != null) {
          _socket?.write(packet.msg);
        } else {
          _sendFail(callSeq, "서버와의 연결이 실패 하였습니다.");
        }
      } on Exception catch (_) {
        _sendFail(callSeq, "전송이 실패하였습니다.");
      }
    }).catchError((error) {
      _sendFail(callSeq, "서버와의 연결이 실패 하였습니다.");
    });
  }

  /// 전송 성공
  void _sendSuccess(int callSeq, String response) {
    if (_syncHashMap.containsKey(callSeq)) {
      _syncHashMap[callSeq]?.(response);
      _syncHashMap.remove(callSeq);
    }
  }

  /// 전송 실패
  void _sendFail(int callSeq, String msg) {
    if (_syncHashMap.containsKey(callSeq)) {
      _syncHashMap[callSeq]?.complete(msg);
      _syncHashMap.remove(callSeq);
    }
  }

  Future<bool> _serverConnect() async {
    if (_isServerConnected()) {
      return true;
    }

    String serverIP = "127.0.0.1";
    int serverPort = 1004;

    await Socket.connect(serverIP, serverPort, timeout: const Duration(seconds: 5)).then((socket) {
      _socket = socket;

      socket.listen((onData) {
        print(String.fromCharCodes(onData).trim());
        // items.insert(
        //     0,
        //     MessageItem(clientSocket!.remoteAddress.address,
        //         String.fromCharCodes(onData).trim()));
      }, onDone:() {
        disconnectServer("onDone");
      }, onError:(e) {
        disconnectServer("onError");
        return false;
      });
    }).catchError((e) {
      disconnectServer("try");
      throw e;
    });
    return true;
  }

  bool _isServerConnected() {
    return _socket != null;
  }

  Future<void> disconnectServer(String? msg) async {
    print("disconnect..$msg");
    _socket?.close();
    _socket = null;
  }

  int _getTcpCount() {
    if (_tcpCount > 10000) _tcpCount = 0;
    return _tcpCount++;
  }
}

class Packet {

  String? msg;

  Packet(String param) {
    msg = param;
  }
}