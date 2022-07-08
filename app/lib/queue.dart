import 'dart:convert';
import 'dart:io';

class QueueRequest {
  final int id;
  final Map data;

  QueueRequest({required this.id, required this.data});
}

class Queue {
  late final Socket socket;

  Future<void> init() async {
    await Socket.connect("127.0.0.1", 4444).then((value) => socket = value);
  }

  bool get isReady {
    return socket != null;
  }

  Stream<QueueRequest> listen() {
    return socket.transform(utf8.decoder.cast()).map((event) {
      final data = jsonDecode(event.toString());
      print(data);
      return QueueRequest(
        id: data["id"],
        data: data["data"],
      );
    });
  }

  finish(int id) {
    socket.write(jsonEncode({"id": id}));
  }
}
