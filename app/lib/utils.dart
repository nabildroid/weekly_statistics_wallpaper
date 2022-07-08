import 'dart:io';
import 'dart:typed_data';

class Utils {
  static List<double> parseDoubles(dynamic data) {
    final s = data.cast<String>() as List<String>;

    return s.map((e) => double.tryParse(e)!).toList();
  }

  static Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}
