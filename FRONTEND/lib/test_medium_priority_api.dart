import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'core/di/injection.dart';
import 'data/data_source/security_remote_datasource.dart';
import 'data/data_source/social_remote_datasource.dart';
import 'data/data_source/geofence_remote_datasource.dart';
import 'data/data_source/distance_remote_datasource.dart';

/// Test file for Medium Priority API Integration
/// Tests: Security, Social, Geofence, Distance features
class MediumPriorityApiTest extends StatefulWidget {
  const MediumPriorityApiTest({super.key});

  @override
  State<MediumPriorityApiTest> createState() => _MediumPriorityApiTestState();
}

class _MediumPriorityApiTestState extends State<MediumPriorityApiTest> {
  final List<TestResult> _results = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medium Priority API Tests'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isRunning ? null : _runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isRunning
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'RUN ALL TESTS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      result.success ? Icons.check_circle : Icons.error,
                      color: result.success ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    title: Text(
                      result.testName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(result.message),
                    trailing: Text(
                      '${result.duration}ms',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_results.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    'Total',
                    _results.length.toString(),
                    Colors.blue,
                  ),
                  _buildStat(
                    'Passed',
                    _results.where((r) => r.success).length.toString(),
                    Colors.green,
                  ),
                  _buildStat(
                    'Failed',
                    _results.where((r) => !r.success).length.toString(),
                    Colors.red,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    // Security Tests
    await _testSecurityDashboard();
    await _testSetup2FA();
    await _testListBiometrics();
    await _testGetAuditLogs();

    // Social Tests
    await _testGetSocialPlatforms();
    await _testGetSocialStatistics();
    await _testGetSocialAnalytics();

    // Geofence Tests
    await _testGetGeofences();
    await _testGetGeofenceTypes();
    await _testGetGeofenceStatistics();
    await _testCheckLocation();

    // Distance Tests
    await _testCalculateDistance();
    await _testGetOverallDistanceStats();

    setState(() {
      _isRunning = false;
    });

    _showSummaryDialog();
  }

  // ==================== SECURITY TESTS ====================

  Future<void> _testSecurityDashboard() async {
    await _runTest(
      'Security Dashboard',
      () async {
        final dataSource = getIt<SecurityRemoteDataSource>();
        final dashboard = await dataSource.getSecurityDashboard();
        
        if (dashboard.activeSessions >= 0) {
          return 'Dashboard loaded: ${dashboard.activeSessions} active sessions';
        }
        throw Exception('Invalid dashboard data');
      },
    );
  }

  Future<void> _testSetup2FA() async {
    await _runTest(
      'Setup 2FA',
      () async {
        final dataSource = getIt<SecurityRemoteDataSource>();
        final setup = await dataSource.setup2FA();
        
        if (setup.secret.isNotEmpty && setup.qrCode.isNotEmpty) {
          return '2FA setup successful with ${setup.backupCodes.length} backup codes';
        }
        throw Exception('Invalid 2FA setup data');
      },
    );
  }

  Future<void> _testListBiometrics() async {
    await _runTest(
      'List Biometrics',
      () async {
        final dataSource = getIt<SecurityRemoteDataSource>();
        final biometrics = await dataSource.listBiometrics();
        return 'Found ${biometrics.length} biometric(s)';
      },
    );
  }

  Future<void> _testGetAuditLogs() async {
    await _runTest(
      'Get Audit Logs',
      () async {
        final dataSource = getIt<SecurityRemoteDataSource>();
        final logs = await dataSource.getAuditLogs(perPage: 10);
        return 'Found ${logs.length} audit log(s)';
      },
    );
  }

  // ==================== SOCIAL TESTS ====================

  Future<void> _testGetSocialPlatforms() async {
    await _runTest(
      'Get Social Platforms',
      () async {
        final dataSource = getIt<SocialRemoteDataSource>();
        final platforms = await dataSource.getSocialPlatforms();
        
        if (platforms.isNotEmpty) {
          final names = platforms.map((p) => p.name).join(', ');
          return 'Found ${platforms.length} platform(s): $names';
        }
        return 'No platforms found';
      },
    );
  }

  Future<void> _testGetSocialStatistics() async {
    await _runTest(
      'Get Social Statistics',
      () async {
        final dataSource = getIt<SocialRemoteDataSource>();
        final stats = await dataSource.getSocialStatistics();
        return 'Total shares: ${stats.totalShares}, Views: ${stats.totalViews}, Clicks: ${stats.totalClicks}';
      },
    );
  }

  Future<void> _testGetSocialAnalytics() async {
    await _runTest(
      'Get Social Analytics',
      () async {
        final dataSource = getIt<SocialRemoteDataSource>();
        final analytics = await dataSource.getSocialAnalytics();
        return 'My shares: ${analytics.myShares}, Engagement: ${analytics.engagementRate.toStringAsFixed(2)}%';
      },
    );
  }

  // ==================== GEOFENCE TESTS ====================

  Future<void> _testGetGeofences() async {
    await _runTest(
      'Get Geofences',
      () async {
        final dataSource = getIt<GeofenceRemoteDataSource>();
        final geofences = await dataSource.getGeofences();
        return 'Found ${geofences.length} geofence(s)';
      },
    );
  }

  Future<void> _testGetGeofenceTypes() async {
    await _runTest(
      'Get Geofence Types',
      () async {
        final dataSource = getIt<GeofenceRemoteDataSource>();
        final types = await dataSource.getGeofenceTypes();
        return 'Available types: ${types.join(", ")}';
      },
    );
  }

  Future<void> _testGetGeofenceStatistics() async {
    await _runTest(
      'Get Geofence Statistics',
      () async {
        final dataSource = getIt<GeofenceRemoteDataSource>();
        final stats = await dataSource.getGeofenceStatistics();
        return 'Total: ${stats.totalGeofences}, Active: ${stats.activeGeofences}, Entries today: ${stats.totalEntriesToday}';
      },
    );
  }

  Future<void> _testCheckLocation() async {
    await _runTest(
      'Check Location (Manila)',
      () async {
        final dataSource = getIt<GeofenceRemoteDataSource>();
        // Manila coordinates
        final check = await dataSource.checkLocation(
          latitude: 14.5995,
          longitude: 120.9842,
        );
        
        if (check.insideGeofence) {
          return 'Inside service area! Found ${check.geofences.length} geofence(s)';
        } else {
          return 'Outside service area';
        }
      },
    );
  }

  // ==================== DISTANCE TESTS ====================

  Future<void> _testCalculateDistance() async {
    await _runTest(
      'Calculate Distance',
      () async {
        final dataSource = getIt<DistanceRemoteDataSource>();
        // Manila to Quezon City
        final distance = await dataSource.calculateDistance(
          fromLat: 14.5995,
          fromLng: 120.9842,
          toLat: 14.6091,
          toLng: 121.0223,
        );
        return 'Distance: ${distance.distanceKm.toStringAsFixed(2)} km (${distance.distanceM.toStringAsFixed(0)} m)';
      },
    );
  }

  Future<void> _testGetOverallDistanceStats() async {
    await _runTest(
      'Get Overall Distance Stats',
      () async {
        final dataSource = getIt<DistanceRemoteDataSource>();
        final stats = await dataSource.getOverallDistanceStats();
        return 'Total: ${stats.totalDistanceKm.toStringAsFixed(2)} km, Orders: ${stats.totalOrders}, Avg: ${stats.averageDistanceKm.toStringAsFixed(2)} km';
      },
    );
  }

  // ==================== TEST RUNNER ====================

  Future<void> _runTest(String testName, Future<String> Function() testFn) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final message = await testFn();
      stopwatch.stop();
      
      setState(() {
        _results.add(TestResult(
          testName: testName,
          success: true,
          message: message,
          duration: stopwatch.elapsedMilliseconds,
        ));
      });
    } catch (e) {
      stopwatch.stop();
      
      String errorMessage = e.toString();
      
      // Parse Dio errors for better messages
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized - Please login first';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Endpoint not found';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error';
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Receive timeout';
        } else {
          errorMessage = e.message ?? 'Unknown error';
        }
      }
      
      setState(() {
        _results.add(TestResult(
          testName: testName,
          success: false,
          message: errorMessage,
          duration: stopwatch.elapsedMilliseconds,
        ));
      });
    }
    
    // Small delay between tests
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void _showSummaryDialog() {
    final passed = _results.where((r) => r.success).length;
    final failed = _results.where((r) => !r.success).length;
    final total = _results.length;
    final successRate = (passed / total * 100).toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              failed == 0 ? Icons.check_circle : Icons.warning,
              color: failed == 0 ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text('Test Summary'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Tests: $total'),
            Text('Passed: $passed', style: const TextStyle(color: Colors.green)),
            Text('Failed: $failed', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Text(
              'Success Rate: $successRate%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (failed > 0) ...[
              const SizedBox(height: 16),
              const Text(
                'Failed Tests:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._results
                  .where((r) => !r.success)
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• ${r.testName}'),
                      )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class TestResult {
  final String testName;
  final bool success;
  final String message;
  final int duration;

  TestResult({
    required this.testName,
    required this.success,
    required this.message,
    required this.duration,
  });
}
