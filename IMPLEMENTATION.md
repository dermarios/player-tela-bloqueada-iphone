# Player Flutter com Tela Bloqueada do iPhone

App Flutter completo de player de áudio com MP3 envelopado e suporte total a controles na tela bloqueada do iPhone.

## Stack Técnica

- **just_audio** (0.10.6) - Reprodução de áudio
- **audio_service** (0.18.19) - Tela bloqueada, Control Center e comandos remotos
- **audio_session** (0.2.4) - Categoria de áudio e gerenciamento de interrupções
- **rxdart** (0.28.0) - Combinação de streams de estado
- **path_provider** (2.1.6) - Acesso ao diretório de documentos

## Estrutura do Projeto

```
lib/
  main.dart                    # Inicialização do AudioService
  audio_player_handler.dart    # Lógica de fundo (BaseAudioHandler)
  ui/
    player_screen.dart         # UI que consome os streams do handler

assets/
  audio/
    track1.mp3                 # MP3 envelopado (3 segundos de teste)
  images/
    cover.jpg                  # Capa do álbum
```

## Configuração iOS CRÍTICA

### 1. UIBackgroundModes (Info.plist)
✓ Configurado automaticamente - adiciona `audio` ao `UIBackgroundModes`

### 2. Deployment Target
✓ iOS 13+ (compatível com audio_service)

### 3. Background Modes Capability
Para adicionar no Xcode:
- Runner → Signing & Capabilities
- Clique em "+ Capability"
- Procure por "Background Modes"
- Marque "Audio, AirPlay, and Picture in Picture"

## Como Usar

### 1. Instalar Dependências
```bash
flutter pub get
cd ios && pod install && cd ..
```

### 2. Build e Run em iPhone Físico
```bash
flutter run -d <device_id>
```

Nota: O Simulador não reproduz fielmente o comportamento de áudio em segundo plano e da tela bloqueada.

## Características Implementadas

✓ **Reprodução de áudio envelopado** - MP3 bundled no assets
✓ **Áudio em segundo plano** - Continua tocando com app minimizado
✓ **Tela bloqueada** - Título, artista, capa e controles
✓ **Control Center** - Acesso aos controles do app
✓ **Play/Pause** - Botão funcional na tela bloqueada
✓ **Avançar/Voltar faixa** - Botões skip funcional
✓ **Barra de progresso arrastável** - Seek na tela bloqueada
✓ **Sincronização de estado** - Botões refletem estado real
✓ **Interrupções** - Trata ligações, fones desconectados
✓ **Dark/Light mode** - UI responsiva ao tema

## Checklist de Validação (em iPhone Físico)

Execute os testes abaixo em iPhone físico com a app instalada:

### Configuração
- [ ] `Info.plist` contém `UIBackgroundModes` → `audio`
- [ ] Background Modes → "Audio, AirPlay..." marcado no Xcode
- [ ] Deployment target ≥ iOS 13
- [ ] `pod install` executado com sucesso

### Reprodução
- [ ] Tocar áudio → bloquear iPhone → áudio continua
- [ ] Na tela bloqueada aparecem título, artista e capa
- [ ] Botão play/pause reflete o estado real
- [ ] Tocar na barra de progresso faz seek

### Interrupções
- [ ] Receber ligação pausa, ao encerrar retoma
- [ ] Desconectar fone de ouvido pausa
- [ ] Com app em segundo plano 5+ minutos, controles respondem

### Controle Center
- [ ] Play/pause funciona do Control Center
- [ ] Avançar/voltar funciona do Control Center
- [ ] Estado sincroniza entre Control Center e tela bloqueada

## Código de Referência Importante

### Main.dart
- Inicializa `AudioService` com `AudioPlayerHandler`
- Configura `AudioServiceConfig` para Android (opcional no iOS)

### AudioPlayerHandler
- Estende `BaseAudioHandler` com `QueueHandler` e `SeekHandler`
- Configura `AudioSession` com categoria `.music()`
- Propaga `playbackEventStream` para sincronizar estado
- Copia artwork do bundle para filesystem (necessário para iOS)
- Trata interrupções e desconexão de fone

### PlayerScreen
- UI que escuta `audioHandler.playbackState`
- Escuta `audioHandler.mediaItem` para título/capa
- Slider que chama `audioHandler.seek()`
- Botões que chamam `audioHandler.play()`, `.pause()`, `.skipToNext()`, `.skipToPrevious()`

## Armadilhas Evitadas

✗ Esquecimento de `UIBackgroundModes` → Causaria corte de áudio
✗ Não propagar `playbackEventStream` → Botões ficariam congelados
✗ Usar asset:// direto para artwork → Capa não apareceria
✗ Chamar player direto da UI → Estado dessincronizaria
✗ Falta de `MediaAction.seek` → Barra não seria arrastável

## Notas de Implementação

- A capa (artwork) é **copiada do bundle para o filesystem** no primeiro run (necessário para iOS renderizar na tela bloqueada)
- O `AudioPlayer` mora no `AudioHandler`, que sobrevive à UI ser descartada
- A UI apenas chama métodos e escuta streams — nunca manipula o player diretamente
- O estado de reprodução é propagado via `playbackState.add()` do `BaseAudioHandler`

## Próximos Passos (Opcional)

1. **Adicionar mais faixas** - Altere a lista `items` em `audio_player_handler.dart`
2. **Carregar artwork dinamicamente** - Implemente busca de capa por internet
3. **Playlist persistente** - Use sqflite ou hive para salvar fila
4. **Integração com Spotify/Apple Music** - Use APIs oficiais
5. **Equalizer** - Implemente via plugins nativos

## Troubleshooting

### Áudio não toca
- Verificar se iPhone não está em silencioso
- Verificar se Background Modes está configurada
- Verificar logs: `flutter logs -v`

### Controles não respondem
- Verificar se `MediaAction.seek` está em `systemActions`
- Verificar se `_broadcastState()` está sendo chamada
- Testar em iPhone físico (simulador não é confiável)

### Capa não aparece
- Verificar se arquivo PNG/JPG está em `assets/images/`
- Verificar se `_prepareArtwork()` copia para filesystem
- Verificar logs de erro em `_prepareArtwork()`

## Build e Deploy

```bash
# Build release para device
flutter build ios --no-codesign

# Para codesigning e distribuição, use Xcode ou:
# flutter build ios --release --build-number=1.0.1
```

## Referências

- [just_audio](https://pub.dev/packages/just_audio)
- [audio_service](https://pub.dev/packages/audio_service)
- [audio_session](https://pub.dev/packages/audio_session)
- [Apple AVAudioSession Documentation](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [iOS Lock Screen Controls](https://developer.apple.com/design/human-interface-guidelines/lockscreen)
