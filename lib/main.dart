import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_editor_app/service_locator.dart';
import 'package:flutter_video_editor_app/ui/project_list.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Director',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        hintColor: Colors.blue,
        brightness: Brightness.dark,
        textTheme: TextTheme(),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      ),
      // localizationsDelegates: [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      // ],
      supportedLocales: [const Locale('en', 'US'), const Locale('es', 'ES')],
      home: Scaffold(body: ProjectList()),
      // navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
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
