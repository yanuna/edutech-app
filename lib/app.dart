import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/api/api_client.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/branding_provider.dart';
import 'core/providers/exam_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'core/providers/test_series_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/startup_service.dart';
import 'shared/theme/app_theme.dart';

// ─── Feature screen imports ────────────────────────────────────────────────
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/auth/screens/verify_mobile_screen.dart';
import 'features/home/home_screen.dart';
import 'features/learn/screens/learn_screen.dart';
import 'features/learn/screens/articles_list_screen.dart';
import 'features/learn/screens/article_reader_screen.dart';
import 'features/learn/screens/saved_articles_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/practice/screens/practice_screen.dart';
import 'features/practice/screens/question_review_screen.dart';
import 'features/progress/screens/progress_dashboard_screen.dart';
import 'features/revision/screens/revision_hub_screen.dart';
import 'features/revision/screens/flashcards_screen.dart';
import 'features/catalog/screens/subjects_screen.dart';
import 'features/catalog/screens/chapters_screen.dart';
import 'features/catalog/screens/topics_screen.dart';
import 'features/catalog/screens/topic_content_screen.dart';
import 'features/exam/screens/exam_setup_screen.dart';
import 'features/exam/screens/exam_screen.dart';
import 'features/exam/screens/exam_result_screen.dart';
import 'features/exam/screens/exam_history_screen.dart';
import 'features/test_series/screens/test_series_screen.dart';
import 'features/test_series/screens/test_series_history_screen.dart';
import 'features/test_series/screens/exam_leaderboard_screen.dart';
import 'features/subscription/screens/plans_screen.dart';
import 'features/subscription/screens/checkout_screen.dart';
import 'features/subscription/screens/payment_success_screen.dart';
import 'features/subscription/screens/payment_webview_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/profile/screens/referral_screen.dart';
import 'features/gamification/screens/leaderboard_screen.dart';
import 'features/news/screens/current_news_screen.dart';
import 'features/current_affairs/screens/current_affairs_screen.dart';
import 'features/notes/screens/notes_screen.dart';
import 'features/notes/screens/editorials_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/support/screens/help_screen.dart';
import 'features/support/screens/about_screen.dart';
import 'features/entities/screens/entities_screen.dart';
import 'features/books/screens/books_screen.dart';
import 'features/govt_jobs/screens/govt_jobs_screen.dart';
import 'features/govt_jobs/screens/govt_job_detail_screen.dart';
import 'features/govt_jobs/screens/saved_jobs_screen.dart';
import 'features/pyq/pyq_screen.dart';
import 'features/pyq/screens/pyq_question_bank_screen.dart';
import 'features/pyq/screens/pyq_trends_screen.dart';
import 'shared/widgets/secure_pdf_viewer.dart';
import 'core/services/pyq_service.dart';

// ─── Shell scaffold (bottom nav) ──────────────────────────────────────────

final _shellKey = GlobalKey<NavigatorState>();

class _AppShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const _AppShell({required this.shell});

  // (branchIndex, icon, activeIcon, label, gating module or null = always shown)
  static const List<
    ({int branch, IconData icon, IconData active, String label, String? module})
  >
  // Display order: Home · Learn · Practice · Current Affairs · Profile.
  // `branch` maps each tab to its StatefulShellBranch index (unchanged), so
  // existing deep routes keep working while the visible order/labels change.
  _tabs = [
    (
      branch: 0,
      icon: Icons.home_outlined,
      active: Icons.home,
      label: 'Home',
      module: null,
    ),
    (
      branch: 1,
      icon: Icons.menu_book_outlined,
      active: Icons.menu_book,
      label: 'Learn',
      module: 'study_material',
    ),
    (
      branch: 2,
      icon: Icons.edit_note_outlined,
      active: Icons.edit_note,
      label: 'Practice',
      module: 'exam',
    ),
    (
      branch: 4,
      icon: Icons.newspaper_outlined,
      active: Icons.newspaper,
      label: 'Current Affairs',
      module: 'news',
    ),
    (
      branch: 3,
      icon: Icons.person_outline,
      active: Icons.person,
      label: 'Profile',
      module: null,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mods = ref.watch(enabledModulesProvider);
    final visible = _tabs
        .where((t) => t.module == null || mods.contains(t.module))
        .toList();

    var current = visible.indexWhere((t) => t.branch == shell.currentIndex);
    if (current < 0) current = 0;

    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: current,
        onTap: (i) {
          final branch = visible[i].branch;
          shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
        },
        items: [
          for (final t in visible)
            BottomNavigationBarItem(
              icon: Icon(t.icon),
              activeIcon: Icon(t.active),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

// ─── Router ────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects when auth changes via a refreshListenable instead of
  // rebuilding the whole router. Recreating the GoRouter (with the same
  // navigatorKey) on every auth change does not reliably re-navigate — e.g.
  // sign-out cleared the session but the screen never moved to /login.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _shellKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (ctx, state) {
      final loc = state.matchedLocation;
      final status = ref.read(authProvider).status;

      if (status == AuthStatus.loading) return null;
      if (loc == '/splash') return null;

      if (status == AuthStatus.unauthenticated) {
        if (loc.startsWith('/onboarding') ||
            loc.startsWith('/login') ||
            loc.startsWith('/register') ||
            loc.startsWith('/forgot-password') ||
            loc.startsWith('/news') ||
            loc.startsWith('/current-affairs')) {
          return null;
        }
        return '/login';
      }

      if (status == AuthStatus.mobileUnverified) {
        if (loc == '/verify-mobile') return null;
        return '/verify-mobile';
      }

      if (status == AuthStatus.unverified) {
        if (loc == '/verify-email') return null;
        return '/verify-email';
      }

      if (status == AuthStatus.authenticated) {
        if (loc == '/login' ||
            loc == '/register' ||
            loc == '/verify-email' ||
            loc == '/verify-mobile') {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, _) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/verify-mobile',
        builder: (_, _) => const VerifyMobileScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          // Branch 1: Learn (hub) + legacy study-material browse (unchanged).
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/learn', builder: (_, _) => const LearnScreen()),
              GoRoute(
                path: '/subjects',
                builder: (_, _) => const SubjectsScreen(),
                routes: [
                  GoRoute(
                    path: ':subjectId/chapters',
                    builder: (_, s) => ChaptersScreen(
                      subjectId: int.parse(s.pathParameters['subjectId']!),
                      subjectName: s.uri.queryParameters['name'] ?? '',
                    ),
                    routes: [
                      GoRoute(
                        path: ':chapterId/topics',
                        builder: (_, s) => TopicsScreen(
                          subjectId: int.parse(s.pathParameters['subjectId']!),
                          chapterId: int.parse(s.pathParameters['chapterId']!),
                          chapterName: s.uri.queryParameters['name'] ?? '',
                        ),
                        routes: [
                          GoRoute(
                            path: ':topicId/content',
                            builder: (_, s) => TopicContentScreen(
                              topicId: int.parse(s.pathParameters['topicId']!),
                              topicName: s.uri.queryParameters['name'] ?? '',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Practice (hub) + legacy exam/test-series flow (unchanged).
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/practice', builder: (_, _) => const PracticeScreen()),
              GoRoute(
                path: '/exam',
                builder: (_, _) => const ExamHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'setup',
                    builder: (_, _) => const ExamSetupScreen(),
                  ),
                  GoRoute(
                    path: ':sessionId/take',
                    builder: (_, s) => ExamScreen(
                      sessionId: int.parse(s.pathParameters['sessionId']!),
                    ),
                  ),
                  GoRoute(
                    path: ':sessionId/result',
                    builder: (_, s) => ExamResultScreen(
                      sessionId: int.parse(s.pathParameters['sessionId']!),
                    ),
                  ),
                  // ── Test Series ────────────────────────────────────────────
                  GoRoute(
                    path: 'test-series',
                    builder: (_, _) => const TestSeriesScreen(),
                  ),
                  GoRoute(
                    path: 'test-series/history',
                    builder: (_, _) => const TestSeriesHistoryScreen(),
                  ),
                  GoRoute(
                    path: 'test-series/:examId/leaderboard',
                    builder: (_, s) => ExamLeaderboardScreen(
                      examId: int.parse(s.pathParameters['examId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, _) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'referral',
                    builder: (_, _) => const ReferralScreen(),
                  ),
                  // Subscription flow + leaderboard are opened from paywalls
                  // and other tabs (Home, Test Series, Practice, etc.). They
                  // must render on the root navigator (parentNavigatorKey), not
                  // the Profile branch's navigator — otherwise a push from
                  // another branch lands on an inactive tab's stack and nothing
                  // appears on screen.
                  GoRoute(
                    path: 'plans',
                    parentNavigatorKey: _shellKey,
                    builder: (_, _) => const PlansScreen(),
                  ),
                  GoRoute(
                    path: 'checkout',
                    parentNavigatorKey: _shellKey,
                    builder: (_, s) => CheckoutScreen(
                      planId: int.parse(s.uri.queryParameters['plan_id']!),
                      gateway: s.uri.queryParameters['gateway'] ?? 'razorpay',
                    ),
                  ),
                  GoRoute(
                    path: 'payment-success',
                    parentNavigatorKey: _shellKey,
                    builder: (_, _) => const PaymentSuccessScreen(),
                  ),
                  GoRoute(
                    path: 'leaderboard',
                    parentNavigatorKey: _shellKey,
                    builder: (_, _) => const LeaderboardScreen(),
                  ),
                  GoRoute(
                    path: 'payment-webview',
                    parentNavigatorKey: _shellKey,
                    builder: (_, s) => PaymentWebViewScreen(
                      orderId: s.uri.queryParameters['order_id'] ?? '',
                      payPageUrl: s.uri.queryParameters['pay_page_url'] ?? '',
                      gatewayName: s.uri.queryParameters['gateway'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ── Branch 4: Current Affairs (structured) + RSS news feed ──────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/current-affairs',
                builder: (_, _) => const CurrentAffairsScreen(),
              ),
              GoRoute(
                path: '/news',
                builder: (_, _) => const CurrentNewsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Government Jobs (full-screen, pushed from Home). 'saved' before ':slug'.
      GoRoute(path: '/govt-jobs', builder: (_, _) => const GovtJobsScreen()),
      GoRoute(
        path: '/govt-jobs/saved',
        builder: (_, _) => const SavedJobsScreen(),
      ),
      GoRoute(
        path: '/govt-jobs/:slug',
        builder: (_, s) => GovtJobDetailScreen(slug: s.pathParameters['slug']!),
      ),

      // Learn — Articles (full-screen over the shell, like PYQs).
      GoRoute(
        path: '/learn/subject/:id',
        builder: (_, s) => ArticlesListScreen(
          subjectId: int.parse(s.pathParameters['id']!),
          subjectName: s.uri.queryParameters['name'] ?? '',
        ),
      ),
      GoRoute(
        path: '/learn/article/:slug',
        builder: (_, s) => ArticleReaderScreen(slug: s.pathParameters['slug']!),
      ),
      GoRoute(path: '/learn/saved', builder: (_, _) => const SavedArticlesScreen()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
      GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
      GoRoute(path: '/editorials', builder: (_, _) => const EditorialsScreen()),
      GoRoute(path: '/entities', builder: (_, _) => const EntitiesScreen()),
      GoRoute(path: '/books', builder: (_, _) => const BooksScreen()),
      GoRoute(path: '/entities/:slug', builder: (_, s) => EntityDetailScreen(slug: s.pathParameters['slug']!)),
      GoRoute(
        path: '/practice/review/:mode',
        builder: (_, s) => QuestionReviewScreen(mode: s.pathParameters['mode']!),
      ),
      GoRoute(path: '/progress', builder: (_, _) => const ProgressDashboardScreen()),
      GoRoute(path: '/revision', builder: (_, _) => const RevisionHubScreen()),
      GoRoute(path: '/revision/flashcards', builder: (_, _) => const FlashcardsScreen()),

      // Previous Year Questions (full-screen, pushed from Home).
      GoRoute(path: '/pyqs', builder: (_, _) => const PyqScreen()),
      GoRoute(path: '/pyqs/bank', builder: (_, _) => const PyqQuestionBankScreen()),
      GoRoute(path: '/pyqs/trends', builder: (_, _) => const PyqTrendsScreen()),
      // Secure in-app viewer: view-only, downloads bytes to memory + caches
      // them AES-encrypted for offline (see PyqService / SecureFileStore).
      GoRoute(
        path: '/pyqs/view/:paperId/:slot',
        builder: (_, s) => SecurePdfViewer.loader(
          () => PyqService.loadPdf(
            int.parse(s.pathParameters['paperId']!),
            s.pathParameters['slot']!,
          ),
          title: s.uri.queryParameters['title'] ?? 'Document',
        ),
      ),
    ],
  );
});

// ─── Root app ─────────────────────────────────────────────────────────────

class EduTechApp extends ConsumerStatefulWidget {
  const EduTechApp({super.key});

  @override
  ConsumerState<EduTechApp> createState() => _EduTechAppState();
}

class _EduTechAppState extends ConsumerState<EduTechApp> {
  @override
  void initState() {
    super.initState();
    _handleNotificationNavigation();
    _listenTokenRefresh();

    // Reset auth state to unauthenticated whenever a request 401s, so the
    // router redirect sends the user back to /login.
    ApiClient.onUnauthorized = () =>
        ref.read(authProvider.notifier).handleUnauthorized();
  }

  // ── Deep-link from notification tap ─────────────────────────────────────

  void _handleNotificationNavigation() {
    final ns = NotificationService.instance;

    // App launched from a terminated state by a notification tap
    ns.getInitialMessage().then(_routeFromMessage);

    // App in background, user taps notification
    ns.onMessageOpenedApp.listen(_routeFromMessage);
  }

  void _routeFromMessage(RemoteMessage? message) {
    if (message == null) return;
    final router = ref.read(routerProvider);

    // Admin broadcasts (from the notification composer) carry type=broadcast +
    // an action. Deep-link where we can, otherwise open the inbox.
    if (message.data['type'] == 'broadcast') {
      final action = message.data['action_type'] as String?;
      final value = message.data['action_value'] as String?;
      if (action == 'article' && value != null && value.isNotEmpty) {
        router.go('/learn/article/$value');
      } else if (action == 'screen' && value != null && value.startsWith('/')) {
        router.go(value);
      } else {
        router.go('/notifications');
      }
      return;
    }

    final screen = message.data['screen'] as String?;
    switch (screen) {
      case 'subscription':
        router.go('/profile/plans');
      case 'exam_result':
        // Only route when the id is a valid integer — the route builder does
        // int.parse() and would throw on a malformed/absent payload value.
        final sessionId = int.tryParse('${message.data['session_id']}');
        if (sessionId != null) router.go('/exam/$sessionId/result');
      default:
        router.go('/home');
    }
  }

  // ── Upload refreshed FCM token ───────────────────────────────────────────

  void _listenTokenRefresh() {
    NotificationService.instance.onTokenRefresh.listen((newToken) {
      // Re-upload whenever Firebase rotates the token
      final authNotifier = ref.read(authProvider.notifier);
      authNotifier.updateFcmToken(newToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final branding = ref.watch(brandingProvider);

    // When the signed-in user changes (login / logout / account switch), drop
    // cached per-user data so a new account never inherits the previous user's
    // subscription status, exam history, or in-progress attempt.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.user?.id != next.user?.id) {
        ref.invalidate(subscriptionStatusProvider);
        ref.invalidate(examHistoryProvider);
        ref.invalidate(activeExamProvider);
        ref.invalidate(testSeriesHistoryProvider);
      }
    });

    return MaterialApp.router(
      title: branding.appName,
      theme: AppTheme.fromColors(
        branding.primaryColor,
        branding.secondaryColor,
      ),
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
