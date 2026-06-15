import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../data/data_source/document_remote_datasource.dart';
import '../../../provider/main/documents/document_provider.dart';
import '../../../widgets/common/retry_widget.dart';
import '../../../widgets/widgets.dart';

class DocumentVerificationScreen extends ConsumerWidget {
  const DocumentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentProvider);
    final notifier = ref.read(documentProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: const AuthHeader(title: 'Documents'),
            ),
            if (state.status != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 16),
                ),
                child: Text(
                  'Status: ${state.status!.overallStatus} '
                  '(${state.status!.verifiedCount}/${state.status!.totalCount} verified)',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
                    )
                  : state.error != null && state.documents.isEmpty
                      ? RetryWidget(
                          message: state.error!,
                          onRetry: notifier.loadAll,
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF5F2D82),
                          onRefresh: notifier.loadAll,
                          child: ListView(
                            padding: EdgeInsets.all(
                              ResponsiveUtils.spacing(context, 16),
                            ),
                            children: [
                              ...state.documents.map(
                                (doc) => ListTile(
                                  tileColor: Colors.grey.shade50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Text(
                                    doc.documentType.replaceAll('_', ' '),
                                    style: const TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${doc.status} · ${doc.documentNumber}',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveUtils.spacing(context, 16),
                              ),
                              OutlinedButton.icon(
                                onPressed: state.isSubmitting
                                    ? null
                                    : () => _showSubmitSheet(context, ref),
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  state.isSubmitting
                                      ? 'Submitting...'
                                      : 'Submit Document',
                                ),
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

  Future<void> _showSubmitSheet(BuildContext context, WidgetRef ref) async {
    final state = ref.read(documentProvider);
    if (state.types.isEmpty) return;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DocumentSubmitSheet(types: state.types),
    );

    if (submitted != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document submitted for review')),
    );
  }
}

class _DocumentSubmitSheet extends ConsumerStatefulWidget {
  const _DocumentSubmitSheet({required this.types});

  final List<DocumentTypeDto> types;

  @override
  ConsumerState<_DocumentSubmitSheet> createState() =>
      _DocumentSubmitSheetState();
}

class _DocumentSubmitSheetState extends ConsumerState<_DocumentSubmitSheet> {
  late String _selectedType;
  final _numberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _selectedFiles = [];
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.types.first.type;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _selectedFiles
        ..clear()
        ..addAll(files.take(5));
    });
  }

  Future<void> _submit() async {
    final number = _numberController.text.trim();
    if (number.isEmpty) {
      setState(() => _error = 'Document number is required.');
      return;
    }
    if (_selectedFiles.isEmpty) {
      setState(() => _error = 'Please attach at least one photo or scan.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final notifier = ref.read(documentProvider.notifier);
      final urls = await notifier.uploadDocumentFiles(_selectedFiles);
      final ok = await notifier.submitDocument(
        documentType: _selectedType,
        documentNumber: number,
        documentUrls: urls,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = ref.read(documentProvider).error ?? 'Submission failed.';
          _submitting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Submit Document',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 18),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedType,
            items: widget.types
                .map(
                  (t) => DropdownMenuItem(
                    value: t.type,
                    child: Text(t.label),
                  ),
                )
                .toList(),
            onChanged: _submitting
                ? null
                : (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
            decoration: const InputDecoration(labelText: 'Document type'),
          ),
          TextField(
            controller: _numberController,
            enabled: !_submitting,
            decoration: const InputDecoration(labelText: 'Document number'),
          ),
          TextField(
            controller: _descriptionController,
            enabled: !_submitting,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              _selectedFiles.isEmpty
                  ? 'Attach photos (required)'
                  : '${_selectedFiles.length} file(s) selected',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontFamily: 'TT Fors'),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Upload & Submit'),
          ),
        ],
      ),
    );
  }
}
