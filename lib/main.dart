
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/news_provider.dart';
import 'providers/settings_provider.dart';
import 'views/home_screen.dart';
import 'utils/web_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Remove splash screen once the app is initialized
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'The Olive Branch',
            themeMode: settings.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: settings.primaryColor,
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.latoTextTheme().copyWith(
                headlineMedium: GoogleFonts.merriweather(),
                titleLarge: GoogleFonts.merriweather(),
                titleMedium: GoogleFonts.merriweather(),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: settings.primaryColor,
                brightness: Brightness.dark,
                surface: Colors.black, // Dark/Black background
              ),
              scaffoldBackgroundColor: Colors.black, // Explicitly black
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
                headlineMedium: GoogleFonts.merriweather(),
                titleLarge: GoogleFonts.merriweather(),
                titleMedium: GoogleFonts.merriweather(),
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
