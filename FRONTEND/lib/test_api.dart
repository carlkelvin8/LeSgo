import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'core/network/dio_client.dart';
import 'core/di/injection.dart';
import 'data/data_source/service_remote_datasource.dart';
import 'data/data_source/partner_remote_datasource.dart';
import 'test_medium_priority_api.dart';

/// Simple API test screen to verify services endpoint
class TestApiScreen extends StatefulWidget {
  const TestApiScreen({super.key});

  @override
  State<TestApiScreen> createState() => _TestApiScreenState();
}

class _TestApiScreenState extends State<TestApiScreen> {
  String _result = 'Press button to test API';
  bool _isLoading = false;

  Future<void> _testPartnersApi() async {
    setState(() {
      _isLoading = true;
      _result = 'Loading partners...\n\nTesting API endpoint:\nhttps://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/partners';
    });

    try {
      final dioClient = getIt<DioClient>();
      final partnerDataSource = PartnerRemoteDataSource(dioClient);
      
      // Test: Get all partners
      final response = await partnerDataSource.getPartners();
      
      if (response.success) {
        setState(() {
          _result = '✅ PARTNERS SUCCESS!\n\n';
          _result += 'Found ${response.data.length} partners:\n';
          _result += 'Total: ${response.meta.total}\n';
          _result += 'Page: ${response.meta.currentPage}/${response.meta.lastPage}\n\n';
          
          for (var partner in response.data) {
            _result += '━━━━━━━━━━━━━━━━━━━━\n';
            _result += '${partner.name}\n';
            _result += 'ID: ${partner.id}\n';
            _result += 'Category: ${partner.category}\n';
            _result += 'Open: ${partner.isOpen ? "✓" : "✗"}\n';
            _result += 'Featured: ${partner.isFeatured ? "✓" : "✗"}\n';
            _result += 'Email: ${partner.contactEmail}\n';
            _result += 'Phone: ${partner.contactPhone}\n';
            if (partner.logoUrl != null) {
              _result += 'Logo: ${partner.logoUrl}\n';
            }
            _result += '\n';
          }
        });
      } else {
        setState(() {
          _result = '❌ PARTNERS API ERROR\n\n';
          _result += 'Error: ${response.error ?? "Unknown error"}\n';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ PARTNERS EXCEPTION\n\n';
        _result += 'Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDirectHttp() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing direct HTTP request...';
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/services',
      );
      
      setState(() {
        _result = '✅ DIRECT HTTP SUCCESS!\n\n';
        _result += 'Status: ${response.statusCode}\n';
        _result += 'Response:\n${response.data}';
      });
    } catch (e) {
      setState(() {
        _result = '❌ DIRECT HTTP FAILED\n\n';
        _result += 'Error: $e\n\n';
        if (e.toString().contains('XMLHttpRequest')) {
          _result += '⚠️ CORS ISSUE DETECTED!\n\n';
          _result += 'The API server needs to allow web requests.\n';
          _result += 'Backend needs to add CORS headers:\n';
          _result += '• Access-Control-Allow-Origin: *\n';
          _result += '• Access-Control-Allow-Methods: GET, POST\n';
          _result += '• Access-Control-Allow-Headers: *\n';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testServicesApi() async {
    setState(() {
      _isLoading = true;
      _result = 'Loading...\n\nTesting API endpoint:\nhttps://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/services';
    });

    try {
      final dioClient = getIt<DioClient>();
      final serviceDataSource = ServiceRemoteDataSource(dioClient);
      
      // Test: Get all services
      final response = await serviceDataSource.getServices();
      
      if (response.success) {
        setState(() {
          _result = '✅ SUCCESS!\n\n';
          _result += 'Found ${response.data.length} services:\n';
          _result += 'Total: ${response.meta.total}\n';
          _result += 'Page: ${response.meta.currentPage}/${response.meta.lastPage}\n\n';
          
          for (var service in response.data) {
            _result += '━━━━━━━━━━━━━━━━━━━━\n';
            _result += '${service.name} (${service.code})\n';
            _result += 'ID: ${service.id}\n';
            _result += 'Base Fare: ₱${service.baseFare.toStringAsFixed(2)}\n';
            _result += 'Per KM: ₱${service.perKmRate.toStringAsFixed(2)}\n';
            _result += 'Min Fare: ₱${service.minimumFare.toStringAsFixed(2)}\n';
            _result += 'Active: ${service.isActive ? "✓" : "✗"}\n';
            if (service.iconUrl != null) {
              _result += 'Icon: ${service.iconUrl}\n';
            }
            _result += '\n';
          }
        });
      } else {
        setState(() {
          _result = '❌ API ERROR\n\n';
          _result += 'Error: ${response.error ?? "Unknown error"}\n\n';
          _result += 'This could be:\n';
          _result += '• CORS issue (API not allowing web requests)\n';
          _result += '• Network connectivity problem\n';
          _result += '• API server is down\n';
          _result += '• Invalid endpoint URL\n';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ EXCEPTION CAUGHT\n\n';
        _result += 'Error: $e\n\n';
        _result += 'Common causes:\n';
        _result += '• CORS policy blocking web requests\n';
        _result += '• Network timeout\n';
        _result += '• Invalid API response format\n\n';
        _result += 'Note: This API might work on mobile\n';
        _result += 'but fail on web due to CORS restrictions.\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Medium Priority Tests Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MediumPriorityApiTest(),
                  ),
                );
              },
              icon: const Icon(Icons.security),
              label: const Text('Test Medium Priority APIs (NEW!)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testDirectHttp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Test Direct HTTP'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _testServicesApi,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Test Services API (with DataSource)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _testPartnersApi,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Test Partners API'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
