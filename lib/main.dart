import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login.dart';

typedef BackendStatusLoader = Future<BackendStatus> Function();

const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.statusLoader});

  final BackendStatusLoader? statusLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventtab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: LoginPage(
        onLogin: () {
          final navigator = NavigationService.navigatorKey.currentState;
          navigator?.push(
            MaterialPageRoute(
              builder: (context) => BackendStatusPage(
                statusLoader: statusLoader ?? fetchBackendStatus,
              ),
            ),
          );
        },
      ),
      navigatorKey: NavigationService.navigatorKey,
    );
  }
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}

Future<BackendStatus> fetchBackendStatus({http.Client? client}) async {
  final httpClient = client ?? http.Client();
  final uri = Uri.parse('$defaultApiBaseUrl/api/health/');

  try {
    final response = await httpClient
        .get(uri)
        .timeout(const Duration(seconds: 5));
    final body = jsonDecode(response.body);

    if (body is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response format.');
    }

    if (response.statusCode != 200) {
      throw BackendConnectionException(
        body['message']?.toString() ??
            'Backend returned HTTP ${response.statusCode}.',
      );
    }

    return BackendStatus.fromJson(body);
  } on TimeoutException {
    throw const BackendConnectionException('Connection timed out.');
  } on FormatException catch (error) {
    throw BackendConnectionException(error.message);
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}

class BackendStatusPage extends StatefulWidget {
  const BackendStatusPage({super.key, required this.statusLoader});

  final BackendStatusLoader statusLoader;

  @override
  State<BackendStatusPage> createState() => _BackendStatusPageState();
}

class _BackendStatusPageState extends State<BackendStatusPage> {
  late Future<BackendStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = widget.statusLoader();
  }

  void _refreshStatus() {
    setState(() {
      _statusFuture = widget.statusLoader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventtab'),
        actions: [
          IconButton(
            tooltip: 'Refresh backend status',
            onPressed: _refreshStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<BackendStatus>(
                future: _statusFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _StatusPanel.loading();
                  }

                  if (snapshot.hasError) {
                    return _StatusPanel.error(
                      message: snapshot.error.toString(),
                      onRetry: _refreshStatus,
                    );
                  }

                  return _StatusPanel.connected(status: snapshot.requireData);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel.connected({required this.status})
    : message = null,
      onRetry = null,
      isLoading = false;

  const _StatusPanel.error({required this.message, required this.onRetry})
    : status = null,
      isLoading = false;

  const _StatusPanel.loading()
    : status = null,
      message = null,
      onRetry = null,
      isLoading = true;

  final BackendStatus? status;
  final String? message;
  final VoidCallback? onRetry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting to backend...'),
        ],
      );
    }

    final isConnected = status != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: isConnected ? Colors.green : colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isConnected
                        ? 'Django backend connected'
                        : 'Backend connection failed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isConnected) ...[
              _InfoRow(label: 'Python backend', value: status!.backend),
              _InfoRow(
                label: 'Database engine',
                value: status!.database.engine,
              ),
              _InfoRow(
                label: 'Database name',
                value: status!.database.currentDatabase,
              ),
              _InfoRow(
                label: 'Database user',
                value: status!.database.currentUser,
              ),
              _InfoRow(
                label: 'PostgreSQL server',
                value:
                    '${status!.database.serverAddr}:${status!.database.serverPort}',
              ),
            ] else ...[
              Text(message ?? 'Unable to reach the Django backend.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class BackendStatus {
  const BackendStatus({
    required this.status,
    required this.backend,
    required this.database,
  });

  final String status;
  final String backend;
  final DatabaseStatus database;

  factory BackendStatus.fromJson(Map<String, dynamic> json) {
    final databaseJson = json['database'];
    if (databaseJson is! Map<String, dynamic>) {
      throw const FormatException('Missing database status.');
    }

    return BackendStatus(
      status: json['status']?.toString() ?? 'unknown',
      backend: json['backend']?.toString() ?? 'unknown',
      database: DatabaseStatus.fromJson(databaseJson),
    );
  }
}

class DatabaseStatus {
  const DatabaseStatus({
    required this.engine,
    required this.configuredName,
    required this.currentDatabase,
    required this.currentUser,
    required this.serverAddr,
    required this.serverPort,
  });

  final String engine;
  final String configuredName;
  final String currentDatabase;
  final String currentUser;
  final String serverAddr;
  final int serverPort;

  factory DatabaseStatus.fromJson(Map<String, dynamic> json) {
    return DatabaseStatus(
      engine: json['engine']?.toString() ?? 'unknown',
      configuredName: json['name']?.toString() ?? 'unknown',
      currentDatabase: json['current_database']?.toString() ?? 'unknown',
      currentUser: json['current_user']?.toString() ?? 'unknown',
      serverAddr: json['server_addr']?.toString() ?? 'unknown',
      serverPort: int.tryParse(json['server_port']?.toString() ?? '') ?? 0,
    );
  }
}

class BackendConnectionException implements Exception {
  const BackendConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
