import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'services/translation_service.dart';
import 'services/speech_service.dart';
import 'services/history_service.dart';
import 'services/learning_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MigranteTraductorApp());
}

class MigranteTraductorApp extends StatelessWidget {
  const MigranteTraductorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TranslationService()),
        ChangeNotifierProvider(create: (_) => SpeechService()),
        ChangeNotifierProvider(create: (_) => HistoryService()..load()),
        ChangeNotifierProvider(create: (_) => LearningService()..load()),
      ],
      child: MaterialApp(
        title: 'Migrante Traductor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.dark,
            primary: const Color(0xFF1E88E5),
            secondary: const Color(0xFF00BCD4),
            surface: const Color(0xFF0A0A0A),
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white.withOpacity(0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.lightBlueAccent,
            selectionColor: Color(0x551E88E5),
            selectionHandleColor: Colors.lightBlueAccent,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            hintStyle: TextStyle(color: Colors.white38),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
