# 🎵 Guia Rápido - Player Flutter com Tela Bloqueada

## ⚡ Setup em 5 minutos

### 1. Pré-requisitos
```bash
flutter --version              # Deve ser 3.13.2+
xcode-select --print-path      # Xcode instalado
```

### 2. Instalar Dependências
```bash
flutter pub get                # Baixa pacotes Dart
cd ios && pod install && cd .. # Instala dependências nativas iOS
```

### 3. Conectar iPhone e Executar
```bash
flutter devices                # Listar dispositivos conectados
flutter run -d <device_id>     # Instala e executa no iPhone
```

## 🔧 Configuração iOS (Já Feita)

Todas as configurações críticas já foram aplicadas:
- ✓ `UIBackgroundModes` → `audio` em Info.plist
- ✓ iOS 13+ deployment target
- ✓ AudioSession configurada para `playback`
- ✓ Artwork copiado para filesystem

## 🎯 Testar na Tela Bloqueada

1. **App aberto** → Toque em Play
2. **Bloqueie o iPhone** → Áudio continua tocando
3. **Puxe de cima para baixo** → Control Center aparece
4. **Control Center** → Botões de controle funcionam
5. **Bloqueio** → Título, artista e capa aparecem

## 📋 Checklist Rápido

```
Áudio em segundo plano
[ ] App em background, áudio continua

Tela bloqueada
[ ] Título e artista aparecem
[ ] Capa (artwork) aparece
[ ] Botões play/pause funcionam
[ ] Skip anterior/próximo funciona
[ ] Barra de progresso é arrastável

Control Center
[ ] Botões controlam o áudio
[ ] Estado sincroniza com lock screen

Interrupções
[ ] Ligação entrante pausa
[ ] Ao desconectar fone, pausa
```

## 🛠️ Estrutura do Código

```
lib/
├── main.dart                    ← Inicializa tudo
├── audio_player_handler.dart    ← Lógica de áudio (🔑 importante)
└── ui/
    └── player_screen.dart       ← Interface
```

**Ponto de entrada:** `AudioPlayerHandler` estende `BaseAudioHandler` do `audio_service`. É o coração do funcionamento na tela bloqueada.

## 🎵 Adicionar Mais Faixas

Em `lib/audio_player_handler.dart`, linha ~51:

```dart
final items = <MediaItem>[
  MediaItem(
    id: 'asset:///assets/audio/track1.mp3',
    title: 'Faixa 1',
    artist: 'Artista',
    // ... adicionar mais aqui
  ),
  MediaItem(
    id: 'asset:///assets/audio/track2.mp3',
    title: 'Faixa 2',
    artist: 'Outro Artista',
  ),
];
```

E adicione os arquivos MP3 em `assets/audio/`.

## 🐛 Troubleshooting

| Problema | Solução |
|----------|---------|
| Áudio não toca | Verificar se iPhone não está mudo |
| Botões não respondem | Restart do app ou device |
| Capa não aparece | Limpar build: `flutter clean && flutter pub get` |
| Xcode não encontra dependências | `cd ios && pod install --repo-update && cd ..` |

## 📖 Documentação Completa

Ver `IMPLEMENTATION.md` para:
- Explicação detalhada de cada componente
- Por que cada dependência foi escolhida
- Armadilhas comuns e como evitá-las
- Referências da documentação oficial

## 🚀 Próximos Passos

1. **Testar em device físico** (simulador não é confiável)
2. **Adicionar mais faixas/assets**
3. **Customizar UI** (cores, fontes, layout)
4. **Integrar com API** (buscar metadados/artwork)
5. **Build release** para App Store

## 💡 Dicas

- O simulador iOS **não funciona bem** para tela bloqueada - use device físico
- A capa é automaticamente copiada do bundle para o filesystem na primeira execução
- Todos os métodos de controle (`play`, `pause`, `seek`, etc) vão através do handler
- A UI espelha o estado - se algo não sincroniza, cheque `_broadcastState()`

---

**Pronto para começar?** Execute `flutter run -d <device_id>` e teste na tela bloqueada! 🎶
