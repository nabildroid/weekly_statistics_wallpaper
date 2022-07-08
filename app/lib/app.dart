import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:weekly_statistics_wallpaper/queue.dart';
import 'package:weekly_statistics_wallpaper/statistics_painter.dart';

import 'utils.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final Queue events = Queue();

  List<QueueRequest> requests = [];

  QueueRequest? get request {
    if (requests.isNotEmpty) return requests.first;
    return null;
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    await events.init();
    events.listen().listen((event) {
      setState(() {
        requests.add(event);
      });
    });
  }

  void nextRequest() {
    if (request == null) return;
    events.finish(request!.id);

    setState(() {
      requests.removeAt(0);
    });
  }

  void generateImage(CustomPainter painter) async {
    const size = Size(360, 700);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.floor(), size.height.floor());
    final pngBytes = await img.toByteData(format: ImageByteFormat.png);
    if (pngBytes != null) {
      await Utils.writeToFile(pngBytes, "/tmp/${request!.id}.png");
      await Future.delayed(const Duration(seconds: 2));
      nextRequest();
    }
  }

  Future<dynamic> fetchStatistics() async {
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

    return [
      Color.fromARGB(255, a[0], a[1], a[2]),
      Color.fromARGB(255, b[0], b[1], b[2]),
    ];
  }

  Future<StatisticsPainter> createStatisticsPainter() async {
    final stats = await fetchStatistics();

    final weeks = stats["weeks"].reversed.toList();
    final isPositive = double.parse(weeks[0]) > double.parse(weeks[1]);
    final colors = await fetchColor(isPositive);

    return StatisticsPainter(
      chartPoints: Utils.parseDoubles(stats["weeks"]),
      productivityValue: stats["productivity"],
      habitPoints: Utils.parseDoubles(stats["habits"]),
      start: stats["start"] != null ? DateTime.parse("2022-06-27") : null,
      primary: colors[0],
      secondary: colors[1],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (request == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<StatisticsPainter>(
      future: createStatisticsPainter(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          generateImage(snapshot.data!);

          return SizedBox.expand(
            child: ColoredBox(
              color: Colors.black,
              child: CustomPaint(painter: snapshot.data!),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
