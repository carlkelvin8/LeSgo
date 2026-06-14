import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../domain/entities/auth/merchant/merchant_documents.dart';
import '../../../../../domain/entities/auth/merchant/merchant_registration_info.dart';
import '../../../../../data/data_source/auth_remote_datasource.dart';
import '../../../../../data/data_source/dto/auth/register_merchant_request_dto.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../data/data_source/helpers/register_merchant_form_builder.dart';
import '../../auth/rider_auth_provider.dart';

// Merchant Register Info State
class MerchantRegisterInfoState {
  final MerchantRegistrationInfo info;
  final MerchantDocuments documents;
  final bool isLoading;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;
  final bool hasAttemptedSubmit;

  // Loading states for individual uploads
  final bool isSelfieLoading;
  final bool isValidIdLoading;
  final bool isSignatureLoading;
  final bool isBarangayPermitLoading;
  final bool isMayorsPermitLoading;
  final bool isDtiPermitLoading;

  const MerchantRegisterInfoState({
    required this.info,
    required this.documents,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
    this.hasAttemptedSubmit = false,
    this.isSelfieLoading = false,
    this.isValidIdLoading = false,
    this.isSignatureLoading = false,
    this.isBarangayPermitLoading = false,
    this.isMayorsPermitLoading = false,
    this.isDtiPermitLoading = false,
  });

  // Presentation getters
  String get presentationRestaurantName =>
      info.restaurantName.isNotEmpty ? info.restaurantName : '—';

  String get presentationAddress =>
      info.address.isNotEmpty ? info.address : '—';

  String get presentationEmail =>
      info.email.isNotEmpty ? info.email : '—';

  String get presentationContactNumber =>
      info.contactNumber.isNotEmpty ? info.contactNumber : '—';

  MerchantRegisterInfoState copyWith({
    MerchantRegistrationInfo? info,
    MerchantDocuments? documents,
    bool? isLoading,
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    bool? hasAttemptedSubmit,
    bool? isSelfieLoading,
    bool? isValidIdLoading,
    bool? isSignatureLoading,
    bool? isBarangayPermitLoading,
    bool? isMayorsPermitLoading,
    bool? isDtiPermitLoading,
    bool clearError = false,
  }) {
    return MerchantRegisterInfoState(
      info: info ?? this.info,
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasAttemptedSubmit: hasAttemptedSubmit ?? this.hasAttemptedSubmit,
      isSelfieLoading: isSelfieLoading ?? this.isSelfieLoading,
      isValidIdLoading: isValidIdLoading ?? this.isValidIdLoading,
      isSignatureLoading: isSignatureLoading ?? this.isSignatureLoading,
      isBarangayPermitLoading:
          isBarangayPermitLoading ?? this.isBarangayPermitLoading,
      isMayorsPermitLoading:
          isMayorsPermitLoading ?? this.isMayorsPermitLoading,
      isDtiPermitLoading: isDtiPermitLoading ?? this.isDtiPermitLoading,
    );
  }

  factory MerchantRegisterInfoState.initial() {
    return MerchantRegisterInfoState(
      info: MerchantRegistrationInfo.empty(),
      documents: MerchantDocuments.empty(),
    );
  }
}

class MerchantRegisterInfoNotifier
    extends StateNotifier<MerchantRegisterInfoState> {
  final Ref ref;

  MerchantRegisterInfoNotifier(this.ref)
    : super(MerchantRegisterInfoState.initial());

  void updateRestaurantName(String value) {
    state = state.copyWith(info: state.info.copyWith(restaurantName: value));
  }

  void updateOwnerFirstName(String value) {
    state = state.copyWith(info: state.info.copyWith(ownerFirstName: value));
  }

  void updateOwnerLastName(String value) {
    state = state.copyWith(info: state.info.copyWith(ownerLastName: value));
  }

  void updateEmail(String value) {
    state = state.copyWith(info: state.info.copyWith(email: value));
  }

  void updateContactNumber(String value) {
    state = state.copyWith(info: state.info.copyWith(contactNumber: value));
  }

  void updateAddress(String value) {
    state = state.copyWith(info: state.info.copyWith(address: value));
  }

  void updateZipCode(String value) {
    state = state.copyWith(info: state.info.copyWith(zipCode: value));
  }

  void updatePassword(String value) {
    state = state.copyWith(info: state.info.copyWith(password: value));
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(info: state.info.copyWith(confirmPassword: value));
  }

  Future<void> uploadSelfie() async {
    state = state.copyWith(isSelfieLoading: true, clearError: true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(selfiePath: image.path),
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to upload selfie: $e');
    } finally {
      state = state.copyWith(isSelfieLoading: false);
    }
  }

  Future<void> uploadValidId() async {
    state = state.copyWith(isValidIdLoading: true, clearError: true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(validIdPath: image.path),
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to upload valid ID: $e');
    } finally {
      state = state.copyWith(isValidIdLoading: false);
    }
  }

  Future<void> uploadDigitalSignature() async {
    state = state.copyWith(isSignatureLoading: true, clearError: true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            digitalSignaturePath: result.files.single.path,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to upload digital signature: $e',
      );
    } finally {
      state = state.copyWith(isSignatureLoading: false);
    }
  }

  Future<void> uploadBarangayPermit() async {
    state = state.copyWith(isBarangayPermitLoading: true, clearError: true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            barangayPermitPath: result.files.single.path,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to upload barangay permit: $e',
      );
    } finally {
      state = state.copyWith(isBarangayPermitLoading: false);
    }
  }

  Future<void> uploadMayorsPermit() async {
    state = state.copyWith(isMayorsPermitLoading: true, clearError: true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            mayorsPermitPath: result.files.single.path,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to upload mayor\'s permit: $e',
      );
    } finally {
      state = state.copyWith(isMayorsPermitLoading: false);
    }
  }

  Future<void> uploadDtiPermit() async {
    state = state.copyWith(isDtiPermitLoading: true, clearError: true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            dtiPermitPath: result.files.single.path,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to upload DTI permit: $e');
    } finally {
      state = state.copyWith(isDtiPermitLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> attemptSubmit() async {
    state = state.copyWith(hasAttemptedSubmit: true, clearError: true);

    // Guard against multiple submissions
    if (state.isSubmitting || state.isSubmitted) return;

    // Validate using entity logic
    if (!state.info.isValid) {
      state = state.copyWith(
        errorMessage: 'Please fill in all required fields correctly.',
      );
      return;
    }

    if (!state.documents.isComplete) {
      state = state.copyWith(
        errorMessage: 'Please upload all required documents.',
      );
      return;
    }

    await _submitForm();
  }

  Future<void> _submitForm() async {
    state = state.copyWith(isSubmitting: true);

    try {
      // Create registration request
      final registerRequest = RegisterMerchantRequestDto(
        name: '${state.info.ownerFirstName} ${state.info.ownerLastName}',
        email: state.info.email,
        phone: state.info.contactNumber,
        password: state.info.password,
        passwordConfirmation: state.info.confirmPassword,
        role: 'partner_admin',
        restaurantName: state.info.restaurantName,
        address: state.info.address,
        zipCode: state.info.zipCode,
        termsAccepted: true,
        privacyAccepted: true,
      );

      final documents = registerMerchantDocumentsFromPaths(
        selfiePath: state.documents.selfiePath!,
        validIdPath: state.documents.validIdPath!,
        digitalSignaturePath: state.documents.digitalSignaturePath!,
        barangayPermitPath: state.documents.barangayPermitPath!,
        mayorsPermitPath: state.documents.mayorsPermitPath!,
        dtiPermitPath: state.documents.dtiPermitPath!,
      );

      final documentError = validateRegisterMerchantDocuments(documents);
      if (documentError != null) {
        throw Exception(documentError);
      }

      final authDataSource = getIt<AuthRemoteDataSource>();
      final response = await authDataSource.registerMerchant(
        registerRequest,
        documents: documents,
      );

      // Store session if registration successful
      if (response.success && response.token != null && response.user != null) {
        final sessionReady = await ref.read(riderAuthProvider.notifier).establishSession(
          token: response.token!,
          refreshToken: response.refreshToken,
          expiresIn: response.expiresIn ?? 3600,
          userData: response.user!.toJson(),
        );

        if (!sessionReady) {
          throw Exception('Registration succeeded but sign-in failed. Please log in.');
        }

        state = state.copyWith(
          isSubmitted: true,
          isSubmitting: false,
        );
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: ApiService.extractError(e),
        isSubmitting: false,
      );
    }
  }
}

final merchantRegisterInfoProvider =
    StateNotifierProvider.autoDispose<
      MerchantRegisterInfoNotifier,
      MerchantRegisterInfoState
    >((ref) {
      return MerchantRegisterInfoNotifier(ref);
    });
