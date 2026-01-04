abstract class AppError {
  final String stackTrace;
  final String errorMessage;
  final String userFriendlyErrorMessage;

  AppError({
    required this.errorMessage,
    required this.userFriendlyErrorMessage,
    required this.stackTrace,
  });
}

class GenericAppError extends AppError {
  GenericAppError({
    required super.errorMessage,
    required super.stackTrace,
    required super.userFriendlyErrorMessage,
  });
}
