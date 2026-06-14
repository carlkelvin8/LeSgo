import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../domain/entities/auth/rider/rider_registration_info.dart';
import '../../../../../domain/entities/auth/rider/rider_documents.dart';
import '../../../../../data/data_source/auth_remote_datasource.dart';
import '../../../../../data/data_source/dto/auth/register_driver_request_dto.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/phone_utils.dart';
import '../../../../../data/data_source/helpers/register_driver_form_builder.dart';
import '../../auth/rider_auth_provider.dart';

// Register Info State
class RegisterInfoState {
  final RiderRegistrationInfo registrationInfo;
  final RiderDocuments documents;
  final bool isSelfieLoading;
  final bool isSelfieMotorcycleLoading;
  final bool isResumeLoading;
  final bool isClearanceLoading;
  final bool isLicenseLoading;
  final bool isMotorcycleImageLoading;
  final bool isScannedORCRLoading;
  final bool isSignatureLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSubmitted;
  final bool hasAttemptedSubmit;

  RegisterInfoState({
    RiderRegistrationInfo? registrationInfo,
    RiderDocuments? documents,
    this.isSelfieLoading = false,
    this.isSelfieMotorcycleLoading = false,
    this.isResumeLoading = false,
    this.isClearanceLoading = false,
    this.isLicenseLoading = false,
    this.isMotorcycleImageLoading = false,
    this.isScannedORCRLoading = false,
    this.isSignatureLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.isSubmitted = false,
    this.hasAttemptedSubmit = false,
  }) : registrationInfo = registrationInfo ?? RiderRegistrationInfo.empty(),
       documents = documents ?? RiderDocuments.empty();

  RegisterInfoState copyWith({
    RiderRegistrationInfo? registrationInfo,
    RiderDocuments? documents,
    bool? isSelfieLoading,
    bool? isSelfieMotorcycleLoading,
    bool? isResumeLoading,
    bool? isClearanceLoading,
    bool? isLicenseLoading,
    bool? isMotorcycleImageLoading,
    bool? isScannedORCRLoading,
    bool? isSignatureLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSubmitted,
    bool? hasAttemptedSubmit,
    bool clearError = false,
  }) {
    return RegisterInfoState(
      registrationInfo: registrationInfo ?? this.registrationInfo,
      documents: documents ?? this.documents,
      isSelfieLoading: isSelfieLoading ?? this.isSelfieLoading,
      isSelfieMotorcycleLoading:
          isSelfieMotorcycleLoading ?? this.isSelfieMotorcycleLoading,
      isResumeLoading: isResumeLoading ?? this.isResumeLoading,
      isClearanceLoading: isClearanceLoading ?? this.isClearanceLoading,
      isLicenseLoading: isLicenseLoading ?? this.isLicenseLoading,
      isMotorcycleImageLoading:
          isMotorcycleImageLoading ?? this.isMotorcycleImageLoading,
      isScannedORCRLoading: isScannedORCRLoading ?? this.isScannedORCRLoading,
      isSignatureLoading: isSignatureLoading ?? this.isSignatureLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitted: isSubmitted ?? this.isSubmitted,
      hasAttemptedSubmit: hasAttemptedSubmit ?? this.hasAttemptedSubmit,
    );
  }

  bool get isFormValid {
    return registrationInfo.isValid && documents.isComplete;
  }

  // Convenience getters for backward compatibility
  String get firstName => registrationInfo.firstName;
  String get lastName => registrationInfo.lastName;
  String get birthday => registrationInfo.birthday;
  String get email => registrationInfo.email;

  // Presentation getters
  String get presentationName {
    final name =
        '${registrationInfo.firstName} ${registrationInfo.lastName}'.trim();
    return name.isNotEmpty ? name : '—';
  }

  String get presentationBirthday => registrationInfo.birthday.isNotEmpty
      ? registrationInfo.birthday
      : '—';

  String get presentationEmail => registrationInfo.email.isNotEmpty
      ? registrationInfo.email
      : '—';

  String get presentationContactNumber {
    final phone = registrationInfo.phoneNumber.trim();
    if (phone.isEmpty) return '—';
    return PhoneUtils.toInternational(phone);
  }

  String? get selfieImagePath => documents.selfieImagePath;
  String? get selfieWithMotorcycleImagePath =>
      documents.selfieWithMotorcycleImagePath;
  String? get resumeFilePath => documents.resumeFilePath;
  String? get barangayClearanceFilePath => documents.barangayClearanceFilePath;
  String? get driversLicenseFilePath => documents.driversLicenseFilePath;
  String? get motorcycleORCRImagePath => documents.motorcycleORCRImagePath;
  String? get scannedORCRFilePath => documents.scannedORCRFilePath;
  String? get digitalSignatureFilePath => documents.digitalSignatureFilePath;
}

class RegisterInfoNotifier extends StateNotifier<RegisterInfoState> {
  final Ref _ref;

  RegisterInfoNotifier(this._ref) : super(RegisterInfoState());

  void updateFirstName(String value) {
    state = state.copyWith(
      registrationInfo: state.registrationInfo.copyWith(firstName: value),
    );
  }

  void updateLastName(String value) {
    state = state.copyWith(
      registrationInfo: state.registrationInfo.copyWith(lastName: value),
    );
  }

  void updateBirthday(String value) {
    state = state.copyWith(
      registrationInfo: state.registrationInfo.copyWith(birthday: value),
    );
  }

  void updateEmail(String value) {
    state = state.copyWith(
      registrationInfo: state.registrationInfo.copyWith(email: value),
    );
  }

  void updatePhoneNumber(String value) {
    state = state.copyWith(
      registrationInfo: state.registrationInfo.copyWith(phoneNumber: value),
    );
  }

  void updatePassword(String value) {
    state = state.copyWith(
      registrationInfo: state.registrationInfo.copyWith(password: value),
    );
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(
      registrationInfo: state.registrationInfo.copyWith(confirmPassword: value),
    );
  }

  void updateLicenseNumber(String value) {
    state = state.copyWith(
      registrationInfo: state.registrationInfo.copyWith(licenseNumber: value),
    );
  }

  void updateLicenseExpiryDate(String? value) {
    state = state.copyWith(
      registrationInfo: state.registrationInfo.copyWith(licenseExpiryDate: value),
    );
  }

  Future<void> uploadSelfie() async {
    try {
      state = state.copyWith(isSelfieLoading: true, clearError: true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(selfieImagePath: image.path),
          isSelfieLoading: false,
        );
      } else {
        state = state.copyWith(isSelfieLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSelfieLoading: false,
        errorMessage: 'Failed to upload selfie: ${e.toString()}',
      );
    }
  }

  Future<void> uploadSelfieWithMotorcycle() async {
    try {
      state = state.copyWith(isSelfieMotorcycleLoading: true, clearError: true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            selfieWithMotorcycleImagePath: image.path,
          ),
          isSelfieMotorcycleLoading: false,
        );
      } else {
        state = state.copyWith(isSelfieMotorcycleLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSelfieMotorcycleLoading: false,
        errorMessage: 'Failed to upload selfie: ${e.toString()}',
      );
    }
  }

  Future<void> uploadResume() async {
    try {
      state = state.copyWith(isResumeLoading: true, clearError: true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            resumeFilePath: result.files.single.path,
          ),
          isResumeLoading: false,
        );
      } else {
        state = state.copyWith(isResumeLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isResumeLoading: false,
        errorMessage: 'Failed to upload resume: ${e.toString()}',
      );
    }
  }

  Future<void> uploadBarangayClearance() async {
    try {
      state = state.copyWith(isClearanceLoading: true, clearError: true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            barangayClearanceFilePath: result.files.single.path,
          ),
          isClearanceLoading: false,
        );
      } else {
        state = state.copyWith(isClearanceLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isClearanceLoading: false,
        errorMessage: 'Failed to upload clearance: ${e.toString()}',
      );
    }
  }

  Future<void> uploadDriversLicense() async {
    try {
      state = state.copyWith(isLicenseLoading: true, clearError: true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            driversLicenseFilePath: result.files.single.path,
          ),
          isLicenseLoading: false,
        );
      } else {
        state = state.copyWith(isLicenseLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLicenseLoading: false,
        errorMessage: 'Failed to upload license: ${e.toString()}',
      );
    }
  }

  Future<void> uploadMotorcycleORCRImage() async {
    try {
      state = state.copyWith(isMotorcycleImageLoading: true, clearError: true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            motorcycleORCRImagePath: result.files.single.path,
          ),
          isMotorcycleImageLoading: false,
        );
      } else {
        state = state.copyWith(isMotorcycleImageLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isMotorcycleImageLoading: false,
        errorMessage: 'Failed to upload OR/CR image: ${e.toString()}',
      );
    }
  }

  Future<void> uploadScannedORCR() async {
    try {
      state = state.copyWith(isScannedORCRLoading: true, clearError: true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            scannedORCRFilePath: result.files.single.path,
          ),
          isScannedORCRLoading: false,
        );
      } else {
        state = state.copyWith(isScannedORCRLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isScannedORCRLoading: false,
        errorMessage: 'Failed to upload scanned OR/CR: ${e.toString()}',
      );
    }
  }

  Future<void> uploadDigitalSignature() async {
    try {
      state = state.copyWith(isSignatureLoading: true, clearError: true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          documents: state.documents.copyWith(
            digitalSignatureFilePath: result.files.single.path,
          ),
          isSignatureLoading: false,
        );
      } else {
        state = state.copyWith(isSignatureLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSignatureLoading: false,
        errorMessage: 'Failed to upload signature: ${e.toString()}',
      );
    }
  }

  void markSubmitAttempted() {
    state = state.copyWith(hasAttemptedSubmit: true);
  }

  /// Validates form fields and documents, then submits if valid.
  /// The [isFormFieldsValid] parameter comes from Form.validate() in the UI.
  void attemptSubmit({required bool isFormFieldsValid}) {
    state = state.copyWith(hasAttemptedSubmit: true);

    // Guard against multiple submissions
    if (state.isSubmitting || state.isSubmitted) return;

    if (isFormFieldsValid && state.documents.isComplete) {
      submitForm();
    } else {
      state = state.copyWith(
        errorMessage:
            'Please fill in all required fields and upload all documents',
      );
    }
  }

  Future<void> submitForm() async {
    if (!state.isFormValid) {
      state = state.copyWith(
        errorMessage:
            'Please fill in all required fields and upload all documents',
      );
      return;
    }

    try {
      state = state.copyWith(isSubmitting: true, clearError: true);

      final info = state.registrationInfo;
      final phoneNumber = PhoneUtils.toInternational(info.phoneNumber);

      final registerRequest = RegisterDriverRequestDto(
        name: '${info.firstName} ${info.lastName}',
        email: info.email,
        phoneNumber: phoneNumber,
        password: info.password,
        passwordConfirmation: info.confirmPassword,
        licenseNumber: info.licenseNumber,
        licenseExpiryDate: _formatDateForApi(info.licenseExpiryDate),
      );

      final documents = registerDriverDocumentsFromPaths(
        selfiePath: state.documents.selfieImagePath!,
        selfieWithMotorcyclePath: state.documents.selfieWithMotorcycleImagePath!,
        resumePath: state.documents.resumeFilePath!,
        barangayClearancePath: state.documents.barangayClearanceFilePath!,
        driversLicensePath: state.documents.driversLicenseFilePath!,
        motorcycleOrcrPath: state.documents.motorcycleORCRImagePath!,
        scannedOrcrPath: state.documents.scannedORCRFilePath!,
        digitalSignaturePath: state.documents.digitalSignatureFilePath!,
      );

      final documentError = validateRegisterDriverDocuments(documents);
      if (documentError != null) {
        throw Exception(documentError);
      }

      final authDataSource = getIt<AuthRemoteDataSource>();
      final response = await authDataSource.registerDriver(
        registerRequest,
        documents: documents,
      );

      // Store session if registration successful
      if (response.success && response.data?.user != null) {
        if (response.token != null) {
          final userData = {
            ...response.data!.user!.toJson(),
            if (response.data!.driverProfile != null)
              'driver_profile': response.data!.driverProfile!.toJson(),
          };

          final sessionReady = await _ref.read(riderAuthProvider.notifier).establishSession(
            token: response.token!,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn ?? 3600,
            userData: userData,
          );

          if (!sessionReady) {
            final loggedIn = await _ref.read(riderAuthProvider.notifier).login(
              info.email,
              info.password,
              rememberMe: false,
              accountType: 'rider',
            );
            if (!loggedIn) {
              throw Exception('Registration succeeded but sign-in failed. Please log in.');
            }
          }
        } else {
          final loggedIn = await _ref.read(riderAuthProvider.notifier).login(
            info.email,
            info.password,
            rememberMe: false,
            accountType: 'rider',
          );
          if (!loggedIn) {
            throw Exception(response.message);
          }
        }

        state = state.copyWith(
          isSubmitting: false,
          isSubmitted: true,
        );
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: ApiService.extractError(e),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = RegisterInfoState();
  }

  String? _formatDateForApi(String? mmddyyyy) {
    if (mmddyyyy == null || mmddyyyy.isEmpty) return null;
    final parts = mmddyyyy.split('/');
    if (parts.length != 3) return mmddyyyy;
    return '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
  }
}

final registerInfoProvider =
    StateNotifierProvider<RegisterInfoNotifier, RegisterInfoState>((ref) {
      return RegisterInfoNotifier(ref);
    });
