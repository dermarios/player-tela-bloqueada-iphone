import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'audio_player_handler.dart';
import 'ui/player_screen.dart';

late AudioPlayerHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🔄 Initializing AudioService...');
    audioHandler = await AudioService.init(
      builder: () {
        print('📦 Building AudioPlayerHandler...');
        return AudioPlayerHandler();
      },
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.exemplo.player.audio',
        androidNotificationChannelName: 'Reprodução de áudio',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    print('✅ AudioService ready');
  } catch (e) {
    print('❌ AudioService Error: $e');
    print('$e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Player Tela Bloqueada',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PlayerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
