import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform, File, Process;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const NamidaIntentDemoApp());
}

class NamidaIntentDemoApp extends StatelessWidget {
  const NamidaIntentDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namida Intent Demo',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const IntentDemoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class IntentDemoScreen extends StatefulWidget {
  const IntentDemoScreen({super.key});

  @override
  State<IntentDemoScreen> createState() => _IntentDemoScreenState();
}

class _IntentDemoScreenState extends State<IntentDemoScreen> {
  String? backupFolder;
  List<String?> musicFolders = [null];
  String? namidaSyncExePath;

  static const platform = MethodChannel('com.example.namida_intent_demo/intent');

  @override
  void initState() {
    super.initState();
    _loadNamidaSyncExePath();
  }

  Future<void> _loadNamidaSyncExePath() async {
    if (!Platform.isWindows) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namidaSyncExePath = prefs.getString('namidaSyncExePath');
    });
  }

  Future<void> _saveNamidaSyncExePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('namidaSyncExePath', path);
    setState(() {
      namidaSyncExePath = path;
    });
  }

  Future<void> pickNamidaSyncExe() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['exe']);
    if (result != null && result.files.single.path != null) {
      await _saveNamidaSyncExePath(result.files.single.path!);
    }
  }

  Future<void> pickBackupFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Pick Backup Folder');
    if (path != null) {
      setState(() {
        backupFolder = path;
      });
    }
  }

  Future<void> pickMusicFolder(int index) async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Pick Music Folder');
    if (path != null) {
      setState(() {
        musicFolders[index] = path;
      });
    }
  }

  void addMusicFolder() {
    setState(() {
      musicFolders.add(null);
    });
  }

  void removeMusicFolder(int index) {
    setState(() {
      musicFolders.removeAt(index);
    });
  }

  Future<void> sendIntentToNamidaSyncDeepLink() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Intent sending is only supported on Android.')));
      return;
    }
    if (backupFolder == null || backupFolder!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a backup folder.')));
      return;
    }
    final validMusicFolders = musicFolders.where((e) => e != null && e.isNotEmpty).map((e) => e).toList();
    final musicFoldersStr = validMusicFolders.join(',');
    final uri = Uri(
      scheme: 'namidasync',
      host: 'config',
      queryParameters: {'backupPath': backupFolder!, 'musicFolders': musicFoldersStr},
    );
    final url = uri.toString();
    try {
      await launchUrl(uri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch Namida Sync: $url')));
    }
  }

  Future<void> sendIntentToNamidaSyncAndroid() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intent sending is only supported on Android.')));
      return;
    }
    if (backupFolder == null || backupFolder!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a backup folder.')));
      return;
    }
    final validMusicFolders = musicFolders.where((e) => e != null && e.isNotEmpty).map((e) => e).toList();
    final musicFoldersStr = validMusicFolders.join(',');
    try {
      await platform.invokeMethod('launchNamidaSync', {
        'backupPath': backupFolder!,
        'musicFolders': musicFoldersStr,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch Namida Sync via platform channel: $e')),
      );
    }
  }

  Future<void> sendIntentToNamidaSyncWindows() async {
    final prefs = await SharedPreferences.getInstance();
    String? exePath = prefs.getString('namidaSyncExePath');
    if (exePath == null || !File(exePath).existsSync()) {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['exe']);
      if (result == null || result.files.single.path == null) {
        // User cancelled
        return;
      }
      exePath = result.files.single.path!;
      await prefs.setString('namidaSyncExePath', exePath);
      setState(() {
        namidaSyncExePath = exePath;
      });
    }
    final validMusicFolders = musicFolders.where((e) => e != null && e.isNotEmpty).map((e) => e!).toList();
    final musicFoldersStr = validMusicFolders.join(',');
    final args = [
      '--backupPath="$backupFolder"',
      '--musicFolders="$musicFoldersStr"',
    ];
    try {
      await Process.start(exePath!, args);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch Namida Sync exe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Namida Intent Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Backup Folder:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: Text(backupFolder ?? 'No folder selected')),
                ElevatedButton(onPressed: pickBackupFolder, child: const Text('Pick')),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Music Library Folders:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate(musicFolders.length, (index) {
              return Row(
                children: [
                  Expanded(child: Text(musicFolders[index] ?? 'No folder selected')),
                  ElevatedButton(onPressed: () => pickMusicFolder(index), child: const Text('Pick')),
                  if (musicFolders.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => removeMusicFolder(index),
                    ),
                ],
              );
            }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: addMusicFolder,
                icon: const Icon(Icons.add),
                label: const Text('Add Music Folder'),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: Platform.isAndroid
                  ? sendIntentToNamidaSyncAndroid
                  : Platform.isWindows
                      ? sendIntentToNamidaSyncWindows
                      : sendIntentToNamidaSyncDeepLink,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Go to Namida Sync'),
            ),
            if (Platform.isWindows)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(namidaSyncExePath ?? 'Namida Sync exe not set'),
                    ),
                    ElevatedButton(
                      onPressed: pickNamidaSyncExe,
                      child: const Text('Pick Namida Sync exe'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
