import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track if terms are accepted (checkbox state)
final termsAcceptedProvider = StateProvider<bool>((ref) => false);

/// Provider to track if user has completed terms step
final hasAcceptedTermsProvider = StateProvider<bool>((ref) => false);
