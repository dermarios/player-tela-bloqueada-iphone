import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'audio_player_handler.dart';
import 'ui/player_screen.dart';

late AudioPlayerHandler audioHandler;
late Future<void> _initFuture;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _initFuture = _initializeAudioService();
  runApp(const MyApp());
}

Future<void> _initializeAudioService() async {
  try {
    debugPrint('🔄 Starting AudioService initialization...');
    audioHandler = await AudioService.init(
      builder: () {
        debugPrint('📦 Creating AudioPlayerHandler...');
        return AudioPlayerHandler();
      },
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.exemplo.player.audio',
        androidNotificationChannelName: 'Reprodução de áudio',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    debugPrint('✅ AudioService initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Error initializing AudioService: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Player Tela Bloqueada',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          return const PlayerScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
