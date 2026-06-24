import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';

class RiderDocumentVerificationScreen extends ConsumerStatefulWidget {
  const RiderDocumentVerificationScreen({super.key});

  @override
  ConsumerState<RiderDocumentVerificationScreen> createState() =>
      _RiderDocumentVerificationScreenState();
}

class _RiderDocumentVerificationScreenState
    extends ConsumerState<RiderDocumentVerificationScreen> {
  List<dynamic> _documents = [];
  List<dynamic> _types = [];
  Map<String, dynamic> _status = {};
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getMyDocuments(),
        ApiService.getDocumentTypes(),
        ApiService.getDocumentVerificationStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _documents = results[0] as List<dynamic>;
        _types = results[1] as List<dynamic>;
        _status = results[2] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  Future<void> _showSubmitSheet() async {
    if (_types.isEmpty) return;
    final picker = ImagePicker();
    String selectedType = _types.first['type']?.toString() ?? 'drivers_license';
    final numberController = TextEditingController();
    final notesController = TextEditingController();
    final files = <XFile>[];

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: _types
                    .map((t) => t as Map<String, dynamic>)
                    .where((t) => t['type'] != null)
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['type'].toString(),
                        child: Text(t['label']?.toString() ?? 'Document'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => selectedType = v);
                },
                decoration: const InputDecoration(labelText: 'Document type'),
              ),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Document number'),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await picker.pickMultiImage(imageQuality: 85);
                  if (picked.isNotEmpty) {
                    setSheetState(() {
                      files
                        ..clear()
                        ..addAll(picked.take(5));
                    });
                  }
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  files.isEmpty
                      ? 'Attach photos (required)'
                      : '${files.length} file(s) selected',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (numberController.text.trim().isEmpty || files.isEmpty) {
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: Text(AppLocalization.translate('continue_document', ref.read(appLanguageProvider))),
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final urls = await ApiService.uploadDocumentFiles(files);
      await ApiService.submitDocument(
        documentType: selectedType,
        documentNumber: numberController.text.trim(),
        documentUrls: urls,
        description: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      await _load();
      if (mounted) {
        final l = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.translate('document_submitted', l))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openDocumentDetail(int docId, Map<String, dynamic> summary, AppLanguage lang) async {
    try {
      final detail = await ApiService.getDocumentById(docId);
      if (!mounted) return;
      final status = detail['status']?.toString() ?? summary['status']?.toString() ?? '';
      final urls = detail['document_urls'] as List? ?? summary['document_urls'] as List? ?? [];

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                detail['document_type']?.toString().replaceAll('_', ' ') ?? 'Document',
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text('Status: $status', style: const TextStyle(fontFamily: 'TT Fors')),
              Text(
                'Number: ${detail['document_number'] ?? summary['document_number']}',
                style: const TextStyle(fontFamily: 'TT Fors'),
              ),
              if (detail['rejection_reason'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Reason: ${detail['rejection_reason']}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    color: Colors.red.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...urls.map(
                (url) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Image.network(
                    url.toString(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(AppLocalization.translate('document_file', lang)),
                    ),
                  ),
                ),
              ),
              if (status.toLowerCase() == 'rejected') ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _resubmitDocument(docId, detail);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                  ),
                  child: Text(AppLocalization.translate('resubmit_document', lang)),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    }
  }

  Future<void> _resubmitDocument(int docId, Map<String, dynamic> detail) async {
    final picker = ImagePicker();
    final numberController = TextEditingController(
      text: detail['document_number']?.toString() ?? '',
    );
    final notesController = TextEditingController();
    final files = <XFile>[];

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Document number'),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await picker.pickMultiImage(imageQuality: 85);
                  if (picked.isNotEmpty) {
                    setSheetState(() {
                      files
                        ..clear()
                        ..addAll(picked.take(5));
                    });
                  }
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  files.isEmpty
                      ? 'Attach new photos (required)'
                      : '${files.length} file(s) selected',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (numberController.text.trim().isEmpty || files.isEmpty) return;
                  Navigator.pop(context, true);
                },
                child: Text(AppLocalization.translate('resubmit', ref.read(appLanguageProvider))),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final urls = await ApiService.uploadDocumentFiles(files);
      await ApiService.resubmitDocument(
        docId,
        documentNumber: numberController.text.trim(),
        documentUrls: urls,
        description: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      await _load();
      if (mounted) {
        final l = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.translate('document_resubmitted', l))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F2D82),
        title: Text(AppLocalization.translate('documents', lang), style: const TextStyle(fontFamily: 'TT Fors')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5F2D82)))
          : _error != null && _documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      TextButton(onPressed: _load, child: Text(AppLocalization.translate('retry', lang))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                    children: [
                      if (_status.isNotEmpty)
                        Text(
                          'Status: ${_status['overall_status'] ?? 'unknown'}',
                          style: const TextStyle(fontFamily: 'TT Fors'),
                        ),
                      const SizedBox(height: 12),
                      ..._documents.map((doc) {
                        final map = doc as Map<String, dynamic>;
                        final docId = (map['id'] as num?)?.toInt();
                        final status = map['status']?.toString() ?? '';
                        return ListTile(
                          tileColor: Colors.grey.shade50,
                          title: Text(
                            map['document_type']?.toString().replaceAll('_', ' ') ??
                                'Document',
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '$status · ${map['document_number']}',
                            style: const TextStyle(fontFamily: 'TT Fors'),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: docId == null
                              ? null
                              : () => _openDocumentDetail(docId, map, lang),
                        );
                      }),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _submitting ? null : _showSubmitSheet,
                        icon: const Icon(Icons.upload_file),
                        label: Text(_submitting ? 'Submitting...' : AppLocalization.translate('documents', lang)),
                      ),
                    ],
                  ),
                ),
    );
  }
}
