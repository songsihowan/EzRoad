  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'firebase_options.dart';
  import 'screens/map_screen.dart';
  import 'package:kakao_map_plugin/kakao_map_plugin.dart';

  // 앱 시작점
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    AuthRepository.initialize(appKey: 'e3f186b5f7455bbd504c7445bdaa865a');

    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 상태바 색상 투명하게 설정
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    runApp(const MyMapApp());
  }

  // 앱 전체를 감싸는 최상위 위젯
  class MyMapApp extends StatelessWidget {
    const MyMapApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: '위험지도',
        debugShowCheckedModeBanner: false,
        // 앱 전체 테마 설정 (다크모드)
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C6AF7),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F0F13),
        ),
        home: const MapScreen(),
      );
    }
  }