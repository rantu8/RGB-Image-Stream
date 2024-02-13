import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

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
        primarySwatch: Colors.blue,
      ),
      home: const ColorPickerWidget(),
    );
  }
}

class ColorPickerWidget extends StatefulWidget {
  const ColorPickerWidget({Key? key}) : super(key: key);

  @override
  _ColorPickerWidgetState createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  String imagePath = 'assets/demoImage.png';
  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();
  GlobalKey containerKey = GlobalKey();

  // CHANGE THIS FLAG TO TEST BASIC IMAGE, AND SNAPSHOT.
  bool useSnapshot = true;

  // based on useSnapshot=true ? paintKey : imageKey ;
  // this key is used in this example to keep the code shorter.
  late GlobalKey currentKey;
  var r = 0, g = 0, b = 0;

  final StreamController<Color> _stateController = StreamController<Color>();
  img.Image? photo;

  @override
  void initState() {
    currentKey = useSnapshot ? paintKey : imageKey;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final String title = useSnapshot ? "snapshot" : "basic";
    return DefaultTabController(
      length: 3,
      child: StreamBuilder(
          initialData: Colors.black,
          stream: _stateController.stream,
          builder: (context, snapshot) {
            Color selectedColor = snapshot.data as Color;
            String c = selectedColor.toString().split('(').last.replaceAll(')', '').replaceAll('0xff', '');
            r = de(c)[0];
            g = de(c)[1];
            b = de(c)[2];
            // ignore: unused_local_variable
            String i = en([r, g, b]);
            if (kDebugMode) {
              print('$r,$g,$b,');
            }
            return Scaffold(
              appBar: AppBar(
                title: const Text("RGB Colors"),
                bottom: TabBar(
                  tabs: [
                    Tab(
                      iconMargin: EdgeInsets.zero,
                      icon: Column(
                        children: [
                          const Text(
                            'R',
                            style: TextStyle(height: 2),
                          ),
                          Text(r.toString()),
                        ],
                      ),
                      // text: 'Strings.top',
                    ),
                    Tab(
                      iconMargin: EdgeInsets.zero,
                      icon: Column(
                        children: [
                          const Text(
                            'G',
                            style: TextStyle(height: 2),
                          ),
                          Text(g.toString()),
                        ],
                      ),
                      // text: 'Strings.top',
                    ),
                    Tab(
                      iconMargin: EdgeInsets.zero,
                      icon: Column(
                        children: [
                          const Text(
                            'B',
                            style: TextStyle(height: 2),
                          ),
                          Text(b.toString()),
                        ],
                      ),
                      // text: 'Strings.top',
                    ),
                  ],
                ),
              ),
              body: RepaintBoundary(
                key: paintKey,
                child: GestureDetector(
                  onPanDown: (details) {
                    searchPixel(details.globalPosition);
                  },
                  onPanUpdate: (details) {
                    searchPixel(details.globalPosition);
                  },
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      key: imageKey,
                      //color: Colors.red,
                      //colorBlendMode: BlendMode.hue,
                      //alignment: Alignment.bottomRight,
                      fit: BoxFit.none,
                      //scale: .8,
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }

  void searchPixel(Offset globalPosition) async {
    if (photo == null) {
      await loadImageBundleBytes();
    }
    _calculatePixel(globalPosition);
  }

  void _calculatePixel(Offset globalPosition) {
    RenderBox box = currentKey.currentContext?.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(globalPosition);

    double px = localPosition.dx;
    double py = localPosition.dy;

    if (!useSnapshot) {
      double widgetScale = box.size.width / photo!.width;
      px = (px / widgetScale);
      py = (py / widgetScale);
    }

    int pixel32 = photo!.getPixelSafe(px.toInt(), py.toInt());
    int hex = abgrToArgb(pixel32);

    _stateController.add(Color(hex));
  }

  Future<void> loadImageBundleBytes() async {
    ByteData imageBytes = await rootBundle.load(imagePath);
    setImageBytes(imageBytes);
  }

  void setImageBytes(ByteData imageBytes) {
    List<int> values = imageBytes.buffer.asUint8List();
    photo = img.decodeImage(values)!;
  }
}

// image lib uses uses KML color format, convert #AABBGGRR to regular #AARRGGBB
int abgrToArgb(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  return (argbColor & 0xFF00FF00) | (b << 16) | r;
}

const String A = "0123456789abcdef";

String en(List<int> b) {
  StringBuffer br = StringBuffer();
  for (int p in b) {
    if (p & 0xff != p) {
      if (kDebugMode) {
        print('There was some exception');
      }
    }
    br.write('${p < 16 ? '0' : ''}${p.toRadixString(16)}');
  }
  return br.toString();
}

List de(String h) {
  String s = h.replaceAll(" ", "");
  s = s.toLowerCase();
  if (s.length % 2 != 0) {
    s = "0" + s;
  }
  Uint8List r = Uint8List(s.length ~/ 2);
  for (int i = 0; i < r.length; i++) {
    int d = A.indexOf(s[i * 2]);
    int d2 = A.indexOf(s[i * 2 + 1]);
    if (d == -1 || d2 == -1) {
      if (kDebugMode) {
        print('There was some exception');
      }
    }
    r[i] = (d << 4) + d2;
  }
  return r;
}
