enum ApiStatus {
  initial,
  loading,
  success,
  expired,
  networkError,
  validationError,
  failure,
}

class ApiResponse {
  final ApiStatus status;
  final String? message;
  final String? data;
  final DateTime? expiryDate;

  ApiResponse({
    required this.status,
    this.message,
    this.data,
    this.expiryDate,
  });
}
