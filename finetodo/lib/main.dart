import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'config/theme.dart';
import 'data/models/task_model.dart';
import 'logic/bloc/task/task_bloc.dart';
import 'logic/bloc/category/category_bloc.dart';
import 'logic/bloc/theme/theme_bloc.dart';
import 'logic/bloc/api_bloc.dart';
import 'presentation/screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(CategoryAdapter());
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<Category>('categories');

  // Initialize timezone
  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => TaskBloc()..add(LoadTasksEvent())),
        BlocProvider(
          create: (context) => CategoryBloc()..add(LoadCategoriesEvent()),
        ),
        BlocProvider(create: (context) => ApiBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Smart To-Do',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
