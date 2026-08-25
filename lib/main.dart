import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whatsapp_clone/constants/colors.dart';
import 'package:whatsapp_clone/core/signal_core.dart';
import 'package:whatsapp_clone/routes.dart';
import 'package:whatsapp_clone/screens/onboarding_screen/onboarding_screen.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL/SUPABASE_ANON_KEY não definidos. '
      'Rode com: flutter run --dart-define-from-file=secrets.json',
    );
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(const WhatsAppClone());
}

class WhatsAppClone extends StatefulWidget {
  const WhatsAppClone({super.key});

  @override
  State<WhatsAppClone> createState() => _WhatsAppCloneState();
}

class _WhatsAppCloneState extends State<WhatsAppClone> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // O Android mata o WebSocket do Realtime quando o app vai pro segundo
    // plano. Quando o app volta (resumed), reconecta e busca o que perdeu.
    if (state == AppLifecycleState.resumed) {
      SignalCore().reconectarSeNecessario();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          color: kAppBarColor,
          iconTheme: IconThemeData(
            color: kIconColor,
          ),
          titleTextStyle: TextStyle(
            color: kTextColor,
            fontSize: 18.0,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kbackgroundColor,
          enableFeedback: false,
          selectedIconTheme: IconThemeData(
            color: kIconColor,
            shadows: [Shadow(color: kbackgroundColor)],
          ),
          selectedItemColor: kTextColor,
          unselectedIconTheme: IconThemeData(
            color: kIconColor,
          ),
          unselectedItemColor: kTextColor,
          type: BottomNavigationBarType.fixed,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          brightness: Brightness.dark,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPrimaryColor,
        ),
        scaffoldBackgroundColor: kbackgroundColor,
        useMaterial3: true,
      ),
      initialRoute: OnboardingScreen.routeName,
      routes: routes,
      home: const OnboardingScreen(),
    );
  }
}
