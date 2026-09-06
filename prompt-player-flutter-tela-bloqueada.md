# Prompt — App Flutter de Player com MP3 Envelopado e Prioridade na Tela Bloqueada do iPhone

> Copie tudo abaixo (a partir de "INÍCIO DO PROMPT") e entregue a um agente de código (Claude Code, Cursor, etc.) ou use como especificação de implementação. O prompt já contém o plano detalhado da tela bloqueada, o código de referência e o checklist de validação para *garantir* que funciona.

---

## INÍCIO DO PROMPT

Você é um desenvolvedor Flutter sênior especialista em áudio nativo iOS. Construa um **app de player de áudio** em Flutter cujo(s) arquivo(s) MP3 estão **envelopados no próprio projeto** (bundled como asset), e cuja **prioridade máxima é a reprodução e o controle na tela bloqueada do iPhone** (Control Center + lock screen). Se qualquer decisão de arquitetura trouxer risco à confiabilidade da tela bloqueada, escolha sempre a opção que a torne mais robusta.

Entregue o app **completo e funcional**, seguindo exatamente a stack, a configuração iOS e a arquitetura abaixo. Não substitua os pacotes por alternativas sem justificar.

### 1. Objetivo

- Tocar um ou mais MP3 embutidos no bundle do app (sem download, sem rede).
- Manter o áudio tocando com o app em segundo plano **e com o iPhone bloqueado**.
- Exibir na tela bloqueada e no Control Center: título, artista, capa (album art) e **barra de progresso funcional**.
- Responder aos botões da tela bloqueada: **play/pause, avançar/voltar faixa, e arrastar a barra de progresso (seek)**.
- Refletir o estado real na tela bloqueada: se pausar pelo Control Center, o botão vira "play" imediatamente, e vice‑versa.
- Tratar interrupções (ligação, outro app de áudio, desconexão de fone) sem travar.

### 2. Stack técnica obrigatória (versões atuais — confirme no pub.dev antes de fixar)

```yaml
dependencies:
  flutter:
    sdk: flutter
  just_audio: ^0.10.5        # reprodução
  audio_service: ^0.18.18    # tela bloqueada / Control Center / comandos remotos
  audio_session: ^0.2.2      # categoria de áudio e interrupções
  rxdart: ^0.28.0            # combinar streams de estado
```

**Por que essa combinação:** `just_audio` só reproduz. `audio_service` é o que cria o processo de fundo e publica o `MediaItem` + `PlaybackState` que o iOS lê para desenhar a tela bloqueada e rotear os toques dos botões de volta para o app. `audio_session` configura a categoria `playback` e gerencia foco/interrupções. Essa é a arquitetura recomendada oficialmente pelo autor (ryanheise) para requisitos de tela bloqueada.

> Alternativa mais simples (apenas se o app tiver **um único** `AudioPlayer` e requisitos triviais): `just_audio_background: ^0.0.1-beta.17` como drop‑in. Ele é internamente construído sobre o `audio_service`, mas dá menos controle. Como aqui a tela bloqueada é prioridade e queremos controle explícito dos comandos e do estado, **use `audio_service` diretamente**.

### 3. Estrutura de projeto esperada

```
lib/
  main.dart                 # inicializa AudioService e injeta o handler
  audio_player_handler.dart # a lógica de fundo (BaseAudioHandler)
  ui/player_screen.dart     # UI que consome os streams do handler
assets/
  audio/track1.mp3          # MP3 envelopado
  images/cover.jpg          # capa exibida na tela bloqueada
```

No `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/audio/
    - assets/images/
```

### 4. Configuração iOS CRÍTICA (sem isto, a tela bloqueada NÃO funciona)

**4.1 — `ios/Runner/Info.plist`: habilitar áudio em segundo plano.** É o item que mais falha se esquecido.
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**4.2 — Capability no Xcode:** em *Runner → Signing & Capabilities → + Capability → Background Modes*, marque **"Audio, AirPlay, and Picture in Picture"**. (Equivale ao item acima; marque de qualquer forma para consistência.)

**4.3 — Categoria da sessão de áudio.** No `main()`, configure `audio_session` com a categoria `playback` **antes** de tocar. Sem `AVAudioSessionCategoryPlayback`, o iOS silencia no bloqueio e não mostra os controles.

**4.4 — Versão mínima de deployment iOS 13+** no `ios/Podfile` e no target do Xcode (o `audio_service` exige). Rode `pod install` após adicionar as dependências.

### 5. Arquitetura — separar UI da lógica de áudio

O `audio_service` roda a lógica de áudio num container que **sobrevive à ausência da UI**. Logo, toda a reprodução mora no `AudioHandler`, e a UI apenas chama métodos e escuta streams. Nunca chame `player.play()` direto da UI — chame `audioHandler.play()`.

### 6. `main.dart` — inicialização (código de referência)

```dart
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'audio_player_handler.dart';

late AudioPlayerHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.exemplo.player.audio',
      androidNotificationChannelName: 'Reprodução de áudio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(const MyApp());
}
```

### 7. `audio_player_handler.dart` — o coração da tela bloqueada (código de referência)

Pontos que **garantem** o funcionamento na tela bloqueada, comentados no código:

```dart
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  // Playlist de MP3s ENVELOPADOS. Cada item carrega o MediaItem (metadados
  // que aparecem na tela bloqueada) via 'tag'.
  final _playlist = ConcateningAudioSource(children: []);

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    // 1) Sessão de áudio: categoria playback -> obrigatório p/ lock screen.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // 2) Propagar TODO evento do just_audio para o audio_service.
    //    Sem isto, os botões da tela bloqueada não refletem o estado real.
    _player.playbackEventStream.listen(_broadcastState);

    // 3) Quando a faixa muda, atualizar o MediaItem atual (título/capa
    //    na tela bloqueada acompanham a faixa que está tocando).
    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // 4) Interrupções (ligação, outro app) e desconexão de fone.
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (event.type == AudioInterruptionType.duck) {
          _player.setVolume(0.3);
        } else {
          _player.pause();
        }
      } else {
        if (event.type == AudioInterruptionType.duck) {
          _player.setVolume(1.0);
        } else if (event.type == AudioInterruptionType.pause) {
          _player.play();
        }
      }
    });
    session.becomingNoisyEventStream.listen((_) => _player.pause());

    // 5) Montar a playlist a partir dos ASSETS envelopados.
    final items = <MediaItem>[
      MediaItem(
        id: 'asset:///assets/audio/track1.mp3',
        album: 'Meu Álbum',
        title: 'Faixa 1',
        artist: 'Artista',
        duration: null, // preenchido após o load
        // Capa da tela bloqueada. Em iOS, prefira um caminho de arquivo
        // real; ver observação sobre artwork no item 9.
        artUri: Uri.parse('asset:///assets/images/cover.jpg'),
      ),
      // ...adicione as demais faixas
    ];

    // Publica a fila para o sistema.
    queue.add(items);
    mediaItem.add(items.first);

    // Carrega as fontes de áudio (asset:// é suportado pelo just_audio).
    await _playlist.addAll([
      for (final item in items) AudioSource.asset(_assetPath(item.id)),
    ]);
    await _player.setAudioSource(_playlist);
  }

  String _assetPath(String id) => id.replaceFirst('asset:///', '');

  // Traduz o estado do just_audio para o PlaybackState que o iOS
  // desenha na tela bloqueada (botões visíveis, posição, buffering, etc.).
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,        // habilita ARRASTAR a barra de progresso
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position, // posição real p/ barra de progresso
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  // ---- Comandos que os botões da tela bloqueada disparam ----
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
}
```

> Observação de API: confirme os nomes exatos (`ConcatenatingAudioSource`, `AudioSource.asset`) na versão fixada do `just_audio`, pois a API de playlists teve ajustes entre versões. Se `AudioSource.asset` não existir na versão, use `AudioSource.uri(Uri.parse('asset:///...'))`.

### 8. UI mínima (`player_screen.dart`)

- Botões que chamam `audioHandler.play()`, `.pause()`, `.skipToNext()`, `.skipToPrevious()`.
- Uma `StreamBuilder` sobre `audioHandler.playbackState` para o ícone play/pause e a posição.
- Uma `StreamBuilder` sobre `audioHandler.mediaItem` para título/capa.
- Um `Slider` de progresso que chama `audioHandler.seek(...)`.

A UI deve ser um espelho do estado — a fonte da verdade é o handler.

### 9. Artwork (capa) na tela bloqueada — armadilha comum do iOS

No iOS, a capa em `artUri` costuma **não aparecer** quando referenciada como `asset:///`. Para garantir:
1. No primeiro run, **copie a imagem do bundle para o diretório de documentos/temporário** do app.
2. Use o caminho de arquivo resultante como `artUri: Uri.file(caminho)`.

Implemente esse "estágio de cópia" antes de publicar o `MediaItem`, para que a capa apareça de forma confiável na tela bloqueada.

### 10. Checklist para GARANTIR que funciona (execute todos)

Testes **em iPhone físico** (o Simulador não reproduz fielmente o comportamento da tela bloqueada):

- [ ] `Info.plist` contém `UIBackgroundModes` → `audio`.
- [ ] Background Modes → "Audio, AirPlay..." marcado no Xcode.
- [ ] `AudioSession` configurada como `.music()` / categoria `playback` antes do primeiro play.
- [ ] `pod install` rodado; deployment target ≥ iOS 13.
- [ ] Tocar áudio → **bloquear o iPhone** → o áudio continua.
- [ ] Na tela bloqueada aparecem título, artista e capa.
- [ ] Botão play/pause da tela bloqueada controla o áudio e **reflete o estado**.
- [ ] Botões avançar/voltar trocam de faixa.
- [ ] Arrastar a barra de progresso faz seek e a posição atualiza.
- [ ] Receber uma ligação pausa e, ao encerrar, retoma (interrupção).
- [ ] Desconectar o fone pausa (becomingNoisy).
- [ ] Com o app totalmente em segundo plano por vários minutos, os controles continuam respondendo.

### 11. Armadilhas conhecidas (previna-as no código)

- **Esquecer o `UIBackgroundModes`** → áudio corta ao bloquear. Erro nº 1.
- **Não propagar `playbackEventStream` para `playbackState`** → os botões da tela bloqueada ficam "congelados"/errados.
- **Não setar `MediaAction.seek` em `systemActions`** → a barra de progresso não é arrastável.
- **`duration` nula no `MediaItem`** → sem barra de progresso; preencha após o load com a duração real do `just_audio`.
- **Chamar o player direto da UI** em vez do handler → estado dessincroniza quando a UI é descartada.
- **artUri como asset** → capa some no iOS; copie para arquivo (item 9).

### 12. Critérios de aceitação (defina "pronto")

O app está pronto quando, em iPhone físico com a tela bloqueada, for possível **iniciar, pausar, retomar, trocar de faixa e arrastar o progresso inteiramente pelos controles da tela bloqueada**, com título/artista/capa corretos, o áudio sobrevivendo ao bloqueio e às interrupções, tudo tocando a partir de MP3 envelopado no bundle (sem rede).

Entregue: `pubspec.yaml`, `Info.plist` ajustado, `main.dart`, `audio_player_handler.dart`, a UI, e instruções de build (`flutter pub get`, `pod install`, run no device).

## FIM DO PROMPT
