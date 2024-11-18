import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MyOMPi961 App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final List<AudioPlayer> _audioPlayers = List.generate(9, (_) => AudioPlayer());
  final List<bool> _isMuted = List.generate(9, (_) => false);
  final List<double> _currentVolume = List.generate(9, (_) => 1.0);
  bool _isPlaying = false;
  double _globalVolume = 1.0;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    var micStatus = await Permission.microphone.request();

    if (micStatus.isGranted) {
      initializeAudioPlayer();
    } else if (micStatus.isDenied) {
      showPermissionDialog('Microphone');
    } else if (micStatus.isPermanentlyDenied) {
      showSettingsDialog('Microphone');
    }
  }

  void showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permission Permission Required'),
          content: Text('This app needs $permission access to function properly.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Grant Permission'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                var status = await Permission.microphone.request();
                if (status.isGranted) {
                  initializeAudioPlayer();
                } else if (status.isPermanentlyDenied) {
                  showSettingsDialog('Microphone');
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

  void showSettingsDialog(String permission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permission Permission Required'),
          content: Text('This app needs $permission access to function properly. Please enable it in the app settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

  void initializeAudioPlayer() {
    // No additional initialization needed for audioplayers in the latest version
  }

  void _fadeVolume(int index, double targetVolume) {
    int steps = 50;
    double stepSize = (_currentVolume[index] - targetVolume) / steps;
    int interval = (5000 ~/ steps);

    Timer.periodic(Duration(milliseconds: interval), (timer) {
      setState(() {
        _currentVolume[index] -= stepSize;
        if ((_currentVolume[index] <= targetVolume && stepSize > 0) ||
            (_currentVolume[index] >= targetVolume && stepSize < 0)) {
          _currentVolume[index] = targetVolume;
          timer.cancel();
        }
        _audioPlayers[index].setVolume(_currentVolume[index] * _globalVolume);
      });
    });
  }

  void _fadeGlobalVolume(double targetVolume) {
    int steps = 50;
    double stepSize = (_globalVolume - targetVolume) / steps;
    int interval = (5000 ~/ steps);

    Timer.periodic(Duration(milliseconds: interval), (timer) {
      setState(() {
        _globalVolume -= stepSize;
        if ((_globalVolume <= targetVolume && stepSize > 0) ||
            (_globalVolume >= targetVolume && stepSize < 0)) {
          _globalVolume = targetVolume;
          timer.cancel();
        }
        for (int i = 0; i < _audioPlayers.length; i++) {
          _audioPlayers[i].setVolume(_currentVolume[i] * _globalVolume);
        }
      });
    });
  }

  void _toggleMute(int index) {
    setState(() {
      if (_isMuted[index]) {
        _fadeVolume(index, 1.0);
      } else {
        _fadeVolume(index, 0.0);
      }
      _isMuted[index] = !_isMuted[index];
    });
  }

  void _togglePlayStop() async {
    // Update the button state immediately
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (!_isPlaying) {
      _fadeGlobalVolume(0.0);
      await Future.delayed(const Duration(seconds: 5));
      for (var player in _audioPlayers) {
        await player.stop();
        await player.seek(Duration.zero);
      }
    } else {
      for (int i = 0; i < _audioPlayers.length; i++) {
        await _audioPlayers[i].setReleaseMode(ReleaseMode.loop);
        await _audioPlayers[i].play(AssetSource('audio/audio${i + 1}.wav'));
        _audioPlayers[i].setVolume(_isMuted[i] ? 0.0 : 1.0);
      }
      _fadeGlobalVolume(1.0);
    }
  }

  Widget _buildAudioPlayer(int index) {
    return GestureDetector(
      onTap: () => _toggleMute(index),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage('assets/images/image${index + 1}.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            if (_isMuted[index])
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int row = 0; row < 3; row++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int col = 0; col < 3; col++)
                        _buildAudioPlayer(row * 3 + col),
                    ],
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(45.0),
              child: GestureDetector(
                onTap: _togglePlayStop,
                child: Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _isPlaying ? '■' : '▶',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 55,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var player in _audioPlayers) {
      player.dispose();
    }
    super.dispose();
  }
}
