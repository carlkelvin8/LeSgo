import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/document_status_label.dart';
import '../../../widgets/main/riderside/profile/profile_panel.dart';

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
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
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
                isExpanded: true,
                initialValue: selectedType,
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
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
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
                child: Text(
                  AppLocalization.translate(
                    'continue_document',
                    ref.read(appLanguageProvider),
                  ),
                ),
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
          SnackBar(
            content: Text(AppLocalization.translate('document_submitted', l)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiService.extractError(e))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openDocumentDetail(
    int docId,
    Map<String, dynamic> summary,
    AppLanguage lang,
  ) async {
    try {
      final detail = await ApiService.getDocumentById(docId);
      if (!mounted) return;
      final status =
          detail['status']?.toString() ?? summary['status']?.toString() ?? '';
      final urls =
          detail['document_urls'] as List? ??
          summary['document_urls'] as List? ??
          [];

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                detail['document_type']?.toString().replaceAll('_', ' ') ??
                    'Document',
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalization.translate('doc_status_label', lang)}: ${documentStatusLabel(status, lang)}',
                style: const TextStyle(fontFamily: 'TT Fors'),
              ),
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
                    errorBuilder: (context, error, stackTrace) => ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(
                        AppLocalization.translate('document_file', lang),
                      ),
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
                  child: Text(
                    AppLocalization.translate('resubmit_document', lang),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiService.extractError(e))));
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
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
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
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
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
                  if (numberController.text.trim().isEmpty || files.isEmpty) {
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: Text(
                  AppLocalization.translate(
                    'resubmit',
                    ref.read(appLanguageProvider),
                  ),
                ),
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
          SnackBar(
            content: Text(AppLocalization.translate('document_resubmitted', l)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiService.extractError(e))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    String tr(String key) => AppLocalization.translate(key, lang);
    final dark = profileDark(context);
    final accent = dark ? const Color(0xFFCFACED) : const Color(0xFF5F2D82);
    final overall =
        _status['overall_status']?.toString().toLowerCase() ??
        (_documents.isEmpty ? 'not_started' : 'unknown');
    final statusColor = switch (overall) {
      'approved' ||
      'verified' => dark ? const Color(0xFF8ED5B0) : const Color(0xFF24754F),
      'rejected' ||
      'action_required' ||
      'expired' => dark ? const Color(0xFFFFB4BC) : const Color(0xFFB63845),
      _ => accent,
    };
    final statusIcon = switch (overall) {
      'approved' || 'verified' => Icons.verified_outlined,
      'rejected' ||
      'action_required' ||
      'expired' => Icons.error_outline_rounded,
      'pending' || 'under_review' => Icons.schedule_rounded,
      _ => Icons.shield_outlined,
    };
    final descriptionKey = switch (overall) {
      'approved' || 'verified' => 'rd_verified_hint',
      'pending' || 'under_review' => 'rd_review_hint',
      'rejected' || 'action_required' || 'expired' => 'rd_action_hint',
      _ => 'rd_intro_hint',
    };
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF17121F) : Colors.white,
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF17121F) : Colors.white,
        foregroundColor: profileText(context),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          tr('documents'),
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _error != null && _documents.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined, color: accent, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: profileText(context)),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(tr('retry')),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: accent,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfilePanel(
                            showBorder: false,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  tr('document_verification'),
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 22,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                    color: profileText(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: .35),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    documentStatusLabel(overall, lang),
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tr(descriptionKey),
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 14,
                                    height: 1.45,
                                    color: profileMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr('rd_your_documents'),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: profileText(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_documents.isEmpty)
                            ProfilePanel(
                              showBorder: false,
                              child: Column(
                                children: [
                                  const SizedBox(height: 4),
                                  Icon(
                                    Icons.folder_open_outlined,
                                    size: 42,
                                    color: accent,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    tr('rd_no_documents'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: profileText(context),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    tr('rd_upload_hint'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 13,
                                      height: 1.5,
                                      color: profileMuted(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            )
                          else
                            ..._documents.map((doc) {
                              final map = doc as Map<String, dynamic>;
                              final docId = (map['id'] as num?)?.toInt();
                              final status = map['status']?.toString() ?? '';
                              final type = map['document_type']?.toString();
                              final matchingTypes = _types.where(
                                (t) => t['type'] == type,
                              );
                              final label = matchingTypes.isEmpty
                                  ? (type?.replaceAll('_', ' ') ??
                                        tr('document'))
                                  : matchingTypes.first['label']?.toString() ??
                                        tr('document');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Material(
                                  color: dark
                                      ? const Color(0xFF241D30)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: BorderSide.none,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    leading: Icon(
                                      Icons.description_outlined,
                                      color: accent,
                                    ),
                                    title: Text(
                                      label,
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: profileText(context),
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${documentStatusLabel(status, lang)} · ${map['document_number'] ?? ''}',
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontSize: 12,
                                          height: 1.5,
                                          color: profileMuted(context),
                                        ),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      color: accent,
                                    ),
                                    onTap: docId == null || _submitting
                                        ? null
                                        : () => _openDocumentDetail(
                                            docId,
                                            map,
                                            lang,
                                          ),
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _submitting || _types.isEmpty
                                ? null
                                : _showSubmitSheet,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF5F2D82),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 13,
                              ),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.upload_file_outlined,
                                    size: 20,
                                  ),
                            label: Text(
                              tr(
                                _submitting
                                    ? 'rd_submitting'
                                    : 'rd_upload_document',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_types.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              tr('rd_types_unavailable'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: profileMuted(context),
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: _load,
                              child: Text(tr('retry')),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.photo_outlined,
                                size: 18,
                                color: profileMuted(context),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tr('rd_photo_tip'),
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 12,
                                    height: 1.5,
                                    color: profileMuted(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
