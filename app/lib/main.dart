import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:weekly_statistics_wallpaper/statistics_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weekly Statisctics Wallpaper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void generateImage(CustomPainter painter) async {
    const size = Size(360, 700);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.floor(), size.height.floor());
    final pngBytes = await img.toByteData(format: ImageByteFormat.png);
    if (pngBytes != null) {
      print("saving");
      await writeToFile(pngBytes, "img.png");
    }

    SystemNavigator.pop();
  }

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<dynamic> fetch() async {
    const endpoint = "https://supernabil.herokuapp.com/ticktick/wallpaper";
    final response = await get(Uri.parse(endpoint));
    return jsonDecode(response.body);
  }

  Future<List<Color>> fetchColor(bool isPositive) async {
    if (!isPositive) return [Colors.white, Colors.black];

    const endpoint = "http://colormind.io/api/";
    final response = await post(
      Uri.parse(endpoint),
      body: jsonEncode({
        "input": [
          "N",
          "N",
          "N",
          "N",
          "N",
        ],
        "model": "default",
      }),
    );

    final result = jsonDecode(response.body)["result"].cast<List<dynamic>>();

    final a = result[3];
    final b = result[1];
    print(b);
    return [
      Color.fromARGB(255, a[0], a[1], a[2]),
      Color.fromARGB(255, b[0], b[1], b[2]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: fetch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final data = snapshot.data;
            final weeks = data["weeks"].reversed.toList();
            final isPositive = double.parse(weeks[0]) > double.parse(weeks[1]);
            return FutureBuilder<List<Color>>(
                future: fetchColor(isPositive),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final colors = snapshot.data!;
                  print(colors[1]);
                  final statisticsPainter = StatisticsPainter(
                    chartPoints: Utils.parseDoubles(data["weeks"]),
                    productivityValue: data["productivity"],
                    habitPoints: Utils.parseDoubles(data["habits"]),
                    start: data["start"] != null
                        ? DateTime.parse("2022-06-27")
                        : null,
                    primary: colors[0],
                    secondary: colors[1],
                  );
                  generateImage(statisticsPainter);

                  return SizedBox.expand(
                    child: ColoredBox(
                      color: Colors.black,
                      child: CustomPaint(painter: statisticsPainter),
                    ),
                  );
                });
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}

class Utils {
  static List<double> parseDoubles(dynamic data) {
    final s = data.cast<String>() as List<String>;

    return s.map((e) => double.tryParse(e)!).toList();
  }
}
