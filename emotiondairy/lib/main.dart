import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'screens/root_shell.dart';
import 'services/emotion_storage.dart';
import 'services/emotion_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SharedPreferencesEmotionRepository.create();
  final store = EmotionStore(repository: repository);
  await store.init();
  runApp(WarmTraceApp(store: store));
}

class WarmTraceApp extends StatelessWidget {
  const WarmTraceApp({super.key, required this.store});

  final EmotionStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '暖迹 · 情绪日记',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scrollBehavior: const _WarmScrollBehavior(),
      home: RootShell(store: store),
    );
  }
}

class _WarmScrollBehavior extends MaterialScrollBehavior {
  const _WarmScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
