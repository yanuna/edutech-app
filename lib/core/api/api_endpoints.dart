import 'package:flutter/foundation.dart' show kReleaseMode;

class ApiEndpoints {
  // Release builds hit production automatically; debug builds use the local
  // emulator host. Update the production URL to your live API domain.
  static const String _production = 'https://visionupsc.in/api';

  // Debug builds talk to a backend on the dev machine. Because a laptop's LAN IP
  // changes between networks, override it at launch without editing code:
  //   flutter run --dart-define=API_BASE_URL=http://<your-LAN-IP>:8000/api
  // The default below is just a convenience fallback (emulator: use 10.0.2.2).
  static const String _localDefault = 'http://10.65.170.61:8000/api';
  static const String _local = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _localDefault,
  );

  static final String baseUrl = kReleaseMode ? _production : _local;

  // Auth
  static const startup = '/startup';
  static const register = '/register';
  static const login = '/login';
  static const socialLogin = '/social-login';
  static const googleAuth = '/social-login';
  static const logout = '/logout';
  static const profile = '/profile';
  static const updateProfile = '/profile';
  static const deleteAccount = '/user/delete-account';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const resendVerification = '/email/verification-notification';
  static const otpSend = '/otp/send';
  static const otpVerify = '/otp/verify';

  // Catalog
  static const subjects = '/catalog/subjects';
  static String chapters(int sid) => '/catalog/subjects/$sid/chapters';
  static String topics(int cid) => '/catalog/chapters/$cid/topics';
  static String topicContent(int tid) => '/topics/$tid/content';

  // Previous Year Questions (view-only PDFs streamed for the secure viewer)
  static const pyqs = '/pyqs';
  static String pyqsForYear(int year) => '/pyqs?year=$year';
  static String pyqFile(int paperId, String slot) => '/pyqs/$paperId/file/$slot';

  // Exam
  static const generateExam = '/exam/generate';
  static String syncExam(int sid) => '/exam/$sid/sync';
  static String submitExam(int sid) => '/exam/$sid/submit';
  static String examResult(int sid) => '/exam/$sid/result';
  static String resumeExam(int sid) => '/exam/$sid/resume';
  static const examHistory = '/exam/history';

  // Test Series (admin-created Part/Full exams)
  static const testSeries = '/test-series';
  static String testSeriesByType(String type) => '/test-series?type=$type';
  static String startTestSeries(int examId) => '/test-series/$examId/start';
  static String testSeriesLeaderboard(int examId) =>
      '/test-series/$examId/leaderboard';
  static const testSeriesHistory = '/test-series/history';

  // Subscription
  static const subscriptionPlans = '/subscriptions/plans';
  static const plans = '/subscriptions/plans';
  static const applyCoupon = '/subscriptions/apply-coupon';
  static const checkout = '/subscriptions/checkout';
  static const verifyPayment = '/subscriptions/verify';
  static const subscriptionVerify = '/subscriptions/verify';
  static const subscriptionStatus = '/subscriptions/status';

  // Govt Jobs
  static const govtJobs = '/govt-jobs';
  static String govtJob(String slug) => '/govt-jobs/$slug';
  static const govtJobsFilters = '/govt-jobs/filters';
  static String govtJobBookmark(String slug) => '/govt-jobs/$slug/bookmark';
  static const govtJobBookmarks = '/my/job-bookmarks';

  // Ads
  static const adsConfig = '/ads-config';

  // Gamification
  static const gamificationProfile = '/gamification/profile';
  static const gamificationLeaderboard = '/gamification/leaderboard';

  // Current News
  static const news = '/news';
  static const newsSources = '/news/sources';
}
