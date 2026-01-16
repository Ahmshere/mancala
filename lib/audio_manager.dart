import 'package:audioplayers/audioplayers.dart';
import 'settings_manager.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // Названия файлов в assets/audio/
  static const String bgMusic = 'background_zen.mp3';
  //static const String stoneDrop = 'stone_click.mp3';
  static const String winSound = 'victory.mp3';
  static const String loseSound = 'defeat.mp3';

  bool isMusicPlaying = false;

  // Инициализация (вызови в main.dart)
  Future<void> init() async {
    _musicPlayer.setReleaseMode(ReleaseMode.loop); // Музыка зациклена
    
  // Устанавливаем громкость сразу при старте
  await _musicPlayer.setVolume(GameSettings.musicVolume);

  }

  // Фоновая музыка
  void playMusic() async {
    if (GameSettings.isMusicOn && !isMusicPlaying) {
      await _musicPlayer.play(AssetSource('audio/$bgMusic'));
      await _musicPlayer.setVolume(GameSettings.musicVolume);
      isMusicPlaying = true;
    }
  }

  void stopMusic() {
    _musicPlayer.stop();
    isMusicPlaying = false;
  }

  void updateMusicVolume() {
    _musicPlayer.setVolume(GameSettings.isMusicOn ? GameSettings.musicVolume : 0);
  }

  // Звуковые эффекты (SFX)
  void playSfx(String fileName) {
    if (GameSettings.isSoundOn) {
      _sfxPlayer.play(AssetSource('audio/$fileName'), volume: GameSettings.sfxVolume);
    }
  }
}