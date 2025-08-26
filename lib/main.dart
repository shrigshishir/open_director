import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_editor_app/service_locator.dart';
import 'package:flutter_video_editor_app/ui/project_list.dart';

void main() {
  //CustomImageCache(); // Disabled at this time
  //setupDevice(); // Disabled at this time
  setupLocator();
  runApp(MyApp());
}

setupDevice() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Status bar disabled
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Director',
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: TextTheme(labelLarge: TextStyle(color: Colors.white)),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(secondary: Colors.blue),
      ),
      // localizationsDelegates: [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      // ],
      supportedLocales: [const Locale('en', 'US'), const Locale('es', 'ES')],
      home: Scaffold(body: ProjectList()),
    );
  }
}

class CustomImageCache extends WidgetsFlutterBinding {
  @override
  ImageCache createImageCache() {
    ImageCache imageCache = super.createImageCache();
    imageCache.maximumSize = 5;
    return imageCache;
  }
}
