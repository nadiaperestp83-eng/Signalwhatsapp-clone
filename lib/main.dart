import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whatsapp_clone/common/screens/homescreen.dart';
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

  // Se já existe uma sessão salva de um cadastro anterior, restaura direto
  // e pula o Onboarding — sem isso, todo restart do app zerava o
  // SignalCore().meuUserId e quebrava qualquer ação que dependesse dele
  // (ex: publicar Story).
  String rotaInicial = OnboardingScreen.routeName;
  final telefoneSalvo = await SignalCore.lerSessaoPersistida();

  if (telefoneSalvo != null) {
    try {
      await SignalCore().inicializarCasulo(meuUserId: telefoneSalvo);
      rotaInicial = HomeScreen.routeName;
    } catch (e) {
      // Sem internet, Supabase fora do ar etc. Cai pro Onboarding em vez de
      // travar o app abrindo.
      // ignore: avoid_print
      print('Não deu pra restaurar a sessão salva: $e');
    }
  }

  runApp(WhatsAppClone(rotaInicial: rotaInicial));
}

class WhatsAppClone extends StatefulWidget {
  final String rotaInicial;

  const WhatsAppClone({super.key, required this.rotaInicial});

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
    // Tema global iOS light + fonte Inter.
    //
    // A maioria das telas do app usa `Text(texto, style: TextStyle(color:
    // kTextColor))` — ou seja, define COR mas não fonte. Quando o Flutter
    // não acha um fontFamily explícito num TextStyle, ele herda do
    // DefaultTextStyle ambiente, que por sua vez vem do textTheme do Theme.
    // Por isso, aplicar o Inter aqui (uma vez) já cobre o app inteiro sem
    // precisar tocar em cada Text() de cada tela.
    final textThemeInter = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: kTextColor,
      displayColor: kTextColor,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: textThemeInter,
        colorScheme: const ColorScheme.light(
          primary: kPrimaryColor,
          onPrimary: Colors.white,
          secondary: kPrimaryColor,
          onSecondary: Colors.white,
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF1C1C1E),
          error: Color(0xFFFF3B30),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: kbackgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: kAppBarColor,
          foregroundColor: kTextColor,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: kIconColor),
          titleTextStyle: GoogleFonts.inter(
            color: kTextColor,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          modalBackgroundColor: Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kbackgroundColor,
          enableFeedback: false,
          selectedIconTheme: IconThemeData(color: kIconColor),
          selectedItemColor: kTextColor,
          unselectedIconTheme: IconThemeData(color: kTextDarkColor),
          unselectedItemColor: kTextDarkColor,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        dividerColor: kDividerColor,
      ),
      initialRoute: widget.rotaInicial,
      routes: routes,
    );
  }
}
