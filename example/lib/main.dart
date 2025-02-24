import 'package:flutter_usual_permission/flutter_usual_permission.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Usual Permission Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PermissionExamplePage(),
    );
  }
}

class PermissionExamplePage extends StatefulWidget {
  const PermissionExamplePage({super.key});

  @override
  State<PermissionExamplePage> createState() => _PermissionExamplePageState();
}

class _PermissionExamplePageState extends State<PermissionExamplePage> {
  String _status = "Permission status will be displayed here";

  /// Check permission status
  Future<void> _checkPermission(PermissionType permissionType) async {
    final hasPermission = await FlutterUsualPermission.checkPermission(
      permissionType,
    );
    setState(() {
      _status =
          hasPermission
              ? "Permission granted for ${permissionType.name}"
              : "Permission denied for ${permissionType.name}";
    });
  }

  /// Request permission
  Future<void> _requestPermission(PermissionType permissionType) async {
    final granted = await FlutterUsualPermission.requestPermission(
      permissionType,
    );
    setState(() {
      _status =
          granted
              ? "Permission granted for ${permissionType.name}"
              : "Permission denied for ${permissionType.name}";
    });
  }

  /// Open notification settings
  Future<void> _openNotificationSettings() async {
    await FlutterUsualPermission.openNotificationSettings();
    setState(() {
      _status = "Opened notification settings";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permission Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _status,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _checkPermission(PermissionType.camera),
              child: const Text('Check Camera Permission'),
            ),
            ElevatedButton(
              onPressed: () => _requestPermission(PermissionType.camera),
              child: const Text('Request Camera Permission'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _checkPermission(PermissionType.microphone),
              child: const Text('Check Microphone Permission'),
            ),
            ElevatedButton(
              onPressed: () => _requestPermission(PermissionType.microphone),
              child: const Text('Request Microphone Permission'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _checkPermission(PermissionType.location),
              child: const Text('Check Location Permission'),
            ),
            ElevatedButton(
              onPressed: () => _requestPermission(PermissionType.location),
              child: const Text('Request Location Permission'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openNotificationSettings,
              child: const Text('Open Notification Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
