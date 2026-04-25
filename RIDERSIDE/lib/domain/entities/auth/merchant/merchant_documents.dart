class MerchantDocuments {
  final String? selfiePath;
  final String? validIdPath;
  final String? digitalSignaturePath;
  final String? barangayPermitPath;
  final String? mayorsPermitPath;
  final String? dtiPermitPath;

  const MerchantDocuments({
    this.selfiePath,
    this.validIdPath,
    this.digitalSignaturePath,
    this.barangayPermitPath,
    this.mayorsPermitPath,
    this.dtiPermitPath,
  });

  bool get isComplete =>
      selfiePath != null &&
      validIdPath != null &&
      digitalSignaturePath != null &&
      barangayPermitPath != null &&
      mayorsPermitPath != null &&
      dtiPermitPath != null;

  MerchantDocuments copyWith({
    String? selfiePath,
    String? validIdPath,
    String? digitalSignaturePath,
    String? barangayPermitPath,
    String? mayorsPermitPath,
    String? dtiPermitPath,
  }) {
    return MerchantDocuments(
      selfiePath: selfiePath ?? this.selfiePath,
      validIdPath: validIdPath ?? this.validIdPath,
      digitalSignaturePath: digitalSignaturePath ?? this.digitalSignaturePath,
      barangayPermitPath: barangayPermitPath ?? this.barangayPermitPath,
      mayorsPermitPath: mayorsPermitPath ?? this.mayorsPermitPath,
      dtiPermitPath: dtiPermitPath ?? this.dtiPermitPath,
    );
  }

  factory MerchantDocuments.empty() {
    return const MerchantDocuments();
  }

  Map<String, dynamic> toJson() {
    return {
      'selfiePath': selfiePath,
      'validIdPath': validIdPath,
      'digitalSignaturePath': digitalSignaturePath,
      'barangayPermitPath': barangayPermitPath,
      'mayorsPermitPath': mayorsPermitPath,
      'dtiPermitPath': dtiPermitPath,
    };
  }

  factory MerchantDocuments.fromJson(Map<String, dynamic> json) {
    return MerchantDocuments(
      selfiePath: json['selfiePath'],
      validIdPath: json['validIdPath'],
      digitalSignaturePath: json['digitalSignaturePath'],
      barangayPermitPath: json['barangayPermitPath'],
      mayorsPermitPath: json['mayorsPermitPath'],
      dtiPermitPath: json['dtiPermitPath'],
    );
  }
}
