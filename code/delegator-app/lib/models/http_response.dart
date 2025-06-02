class Response<T> {
  final int statusCode;
  final T? data;
  final String? error;
  final bool isSuccess;

  Response({
    required this.statusCode,
    this.data,
    this.error,
  }) : isSuccess = statusCode >= 200 && statusCode < 300;

  factory Response.success(int statusCode, T data) {
    return Response<T>(
      statusCode: statusCode,
      data: data,
    );
  }

  factory Response.error(int statusCode, String error) {
    return Response<T>(
      statusCode: statusCode,
      error: error,
    );
  }

  @override
  String toString() {
    return 'HttpResponse(statusCode: $statusCode, isSuccess: $isSuccess, '
        'data: $data, error: $error)';
  }
}
