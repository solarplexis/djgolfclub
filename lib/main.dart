import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/course_provider.dart';
import 'providers/player_provider.dart';
import 'providers/round_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await dotenv.load(fileName: '.env');
  runApp(const DJGolfCardApp());
}

class DJGolfCardApp extends StatelessWidget {
  const DJGolfCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseProvider()..load()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()..load()),
        ChangeNotifierProvider(create: (_) => RoundProvider()..load()),
      ],
      child: MaterialApp(
        title: 'DJ Golf Card',
        theme: buildAppTheme(),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
