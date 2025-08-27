import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/project/project_bloc.dart';
import 'package:flutter_video_editor_app/repository/project_repository.dart';
import 'package:flutter_video_editor_app/ui/project_list.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //CustomImageCache(); // Disabled at this time
  //setupDevice(); // Disabled at this time
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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProjectRepository>(
          create: (context) => ProjectRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ProjectBloc>(
            create: (context) => ProjectBloc(
              projectRepository: context.read<ProjectRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Open Director',
          theme: ThemeData(
            brightness: Brightness.dark,
            textTheme: TextTheme(labelLarge: TextStyle(color: Colors.white)),
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
            ).copyWith(secondary: Colors.blue),
          ),
          supportedLocales: [
            const Locale('en', 'US'),
            const Locale('es', 'ES'),
          ],
          home: Scaffold(body: ProjectList()),
        ),
      ),
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
