import 'app_localization.dart';

String documentStatusLabel(Object? status, AppLanguage language) {
  final value = status?.toString().trim().toLowerCase();
  const known = {
    'not_started',
    'pending',
    'under_review',
    'approved',
    'verified',
    'rejected',
    'action_required',
    'expired',
  };
  return AppLocalization.translate(
    'doc_status_${known.contains(value) ? value : 'unknown'}',
    language,
  );
}
