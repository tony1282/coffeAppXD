// core/network/retry_policy.dart

class RetryPolicy {
  static const int maxRetries = 1;
  
  static bool shouldRetry(int statusCode, int attempt) {
    return statusCode == 401 && attempt < maxRetries;
  }
}