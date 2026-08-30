import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/cooperative/presentation/pages/cooperative_welcome_page.dart';
import '../../features/customer/presentation/cubit/booking_flow_cubit.dart';
import '../../features/customer/presentation/cubit/tracking_cubit.dart';
import '../../features/customer/presentation/pages/customer_add_parts_page.dart';
import '../../features/customer/presentation/pages/customer_ai_discovery_page.dart';
import '../../features/customer/presentation/pages/customer_ai_helper_page.dart';
import '../../features/customer/presentation/pages/customer_ai_workers_page.dart';
import '../../features/customer/presentation/pages/customer_booking_confirmation_page.dart';
import '../../features/customer/presentation/pages/customer_booking_page.dart';
import '../../features/customer/presentation/pages/customer_categories_page.dart';
import '../../features/customer/presentation/pages/customer_finding_worker_page.dart';
import '../../features/customer/presentation/pages/customer_home_booking_page.dart';
import '../../features/customer/presentation/pages/customer_home_page.dart';
import '../../features/customer/presentation/pages/customer_payment_page.dart';
import '../../features/customer/presentation/pages/customer_price_estimate_page.dart';
import '../../features/customer/presentation/pages/customer_rating_page.dart';
import '../../features/customer/presentation/pages/customer_search_page.dart';
import '../../features/customer/presentation/pages/customer_service_detail_page.dart';
import '../../features/customer/presentation/pages/customer_tracking_page.dart';
import '../../features/customer/presentation/pages/customer_work_started_page.dart';
import '../../features/customer/presentation/pages/customer_worker_accepted_page.dart';
import '../../features/customer/presentation/pages/customer_worker_profile_page.dart';
import '../../features/customer/presentation/pages/customer_workers_page.dart';
import '../../features/demo/presentation/pages/demo_hub_page.dart';
import '../../features/language/presentation/pages/language_page.dart';
import '../../features/role/presentation/pages/role_picker_page.dart';
import '../../features/shared/presentation/cubit/notifications_cubit.dart';
import '../../features/shared/presentation/cubit/profile_cubit.dart';
import '../../features/shared/presentation/cubit/support_cubit.dart';
import '../../features/shared/presentation/pages/edit_profile_page.dart';
import '../../features/shared/presentation/pages/notifications_page.dart';
import '../../features/shared/presentation/pages/order_history_page.dart';
import '../../features/shared/presentation/pages/profile_hub_page.dart';
import '../../features/shared/presentation/pages/settings_page.dart';
import '../../features/shared/presentation/pages/sos_page.dart';
import '../../features/shared/presentation/pages/support_chat_page.dart';
import '../../features/shared/presentation/pages/support_ticket_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/system/presentation/pages/system_state_page.dart';
import '../../features/worker/presentation/cubit/active_job_cubit.dart';
import '../../features/worker/presentation/cubit/job_feed_cubit.dart';
import '../../features/worker/presentation/cubit/wallet_cubit.dart';
import '../../features/worker/presentation/cubit/worker_dashboard_cubit.dart';
import '../../features/worker/presentation/cubit/worker_onboarding_cubit.dart';
import '../../features/worker/presentation/pages/onboarding/worker_aadhaar_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_availability_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_bank_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_certificate_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_onboarding_status_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_pan_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_personal_details_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_selfie_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_service_area_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_skills_page.dart';
import '../../features/worker/presentation/pages/onboarding/worker_welfare_page.dart';
import '../../features/worker/presentation/pages/worker_active_job_page.dart';
import '../../features/worker/presentation/pages/worker_availability_status_page.dart';
import '../../features/worker/presentation/pages/worker_dashboard_page.dart';
import '../../features/worker/presentation/pages/worker_earnings_page.dart';
import '../../features/worker/presentation/pages/worker_incoming_orders_page.dart';
import '../../features/worker/presentation/pages/worker_job_feed_page.dart';
import '../../features/worker/presentation/pages/worker_navigation_page.dart';
import '../../features/worker/presentation/pages/worker_order_detail_page.dart';
import '../../features/worker/presentation/pages/worker_profile_page.dart';
import '../../features/worker/presentation/pages/worker_reliability_page.dart';
import '../../features/worker/presentation/pages/worker_wallet_page.dart';
import '../../core/widgets/customer_main_shell.dart';
import '../../core/widgets/worker_main_shell.dart';
import 'router_helpers.dart';
import 'route_names.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    routes: [
      _page(RouteNames.splash, (_, s) => const SplashPage()),
      _page(RouteNames.language, (_, s) => const LanguagePage()),
      _page(RouteNames.cooperative, (_, s) => const CooperativeWelcomePage()),
      _page(RouteNames.role, (_, s) => const RolePickerPage()),
      _page(RouteNames.login, (_, s) => const LoginPage()),
      _page(RouteNames.signup, (_, s) => const SignupPage()),
      _page(RouteNames.otp, (_, s) => const OtpPage()),
      if (kDebugMode)
        _page(RouteNames.demo, (_, s) => const DemoHubPage()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomerMainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              _page(RouteNames.customerHome, (_, s) => const CustomerHomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _page(RouteNames.customerSearch, (_, s) => const CustomerSearchPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _page(RouteNames.customerAiHelper, (_, s) => const CustomerAiHelperPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _page(RouteNames.customerOrders, (_, s) => const OrderHistoryPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _page(
                RouteNames.customerProfileTab,
                (_, s) => BlocProvider(
                  create: (_) => ProfileCubit()..load(),
                  child: const ProfileHubPage(),
                ),
              ),
            ],
          ),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return WorkerMainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              _page(
                RouteNames.workerDashboard,
                (_, s) => BlocProvider(
                  create: (_) => WorkerDashboardCubit()..load(),
                  child: const WorkerDashboardPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _page(
                RouteNames.workerJobs,
                (_, s) => BlocProvider(
                  create: (_) => JobFeedCubit()..load(),
                  child: const WorkerJobFeedPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _page(
                RouteNames.workerWallet,
                (_, s) => BlocProvider(
                  create: (_) => WalletCubit()..load(),
                  child: const WorkerWalletPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _page(
                RouteNames.workerProfileTab,
                (_, s) => BlocProvider(
                  create: (_) => ProfileCubit()..load(),
                  child: const WorkerProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Customer booking shell — shared BookingFlowCubit + TrackingCubit
      ShellRoute(
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => BookingFlowCubit()),
              BlocProvider(create: (_) => TrackingCubit()),
            ],
            child: child,
          );
        },
        routes: [
          _page(RouteNames.customerBooking, (_, s) => const CustomerBookingPage()),
          _page(
            RouteNames.customerPriceEstimate,
            (_, s) => const CustomerPriceEstimatePage(),
          ),
          _page(
            RouteNames.customerFindingWorker,
            (_, s) => const CustomerFindingWorkerPage(),
          ),
          _page(
            RouteNames.customerWorkerAccepted,
            (_, s) => const CustomerWorkerAcceptedPage(),
          ),
          _page(RouteNames.customerTracking, (_, s) => const CustomerTrackingPage()),
          _page(
            RouteNames.customerWorkStarted,
            (_, s) => const CustomerWorkStartedPage(),
          ),
          _page(RouteNames.customerAddParts, (_, s) => const CustomerAddPartsPage()),
          _page(RouteNames.customerPayment, (_, s) => const CustomerPaymentPage()),
          _page(RouteNames.customerRating, (_, s) => const CustomerRatingPage()),
          _page(
            RouteNames.customerBookingConfirmation,
            (_, s) => const CustomerBookingConfirmationPage(),
          ),
        ],
      ),

      _page(
        RouteNames.customerCategories,
        (_, s) => const CustomerCategoriesPage(),
      ),
      GoRoute(
        path: RouteNames.customerService,
        pageBuilder: (context, state) => transitPage(
          key: state.pageKey,
          child: CustomerServiceDetailPage(
            serviceId: state.pathParameters['id']!,
          ),
        ),
      ),
      _page(
        RouteNames.customerHomeBooking,
        (_, s) => const CustomerHomeBookingPage(),
      ),
      _page(
        RouteNames.customerAiDiscovery,
        (_, s) => const CustomerAiDiscoveryPage(),
      ),
      _page(
        RouteNames.customerAiWorkers,
        (_, s) => const CustomerAiWorkersPage(),
      ),
      _page(RouteNames.customerWorkers, (_, s) => const CustomerWorkersPage()),
      GoRoute(
        path: RouteNames.customerWorkerProfile,
        pageBuilder: (context, state) => transitPage(
          key: state.pageKey,
          child: CustomerWorkerProfilePage(
            workerId: state.pathParameters['id']!,
          ),
        ),
      ),

      // Worker onboarding shell
      ShellRoute(
        builder: (context, state, child) {
          return BlocProvider(
            create: (_) => WorkerOnboardingCubit(),
            child: child,
          );
        },
        routes: [
          _page(
            RouteNames.workerOnboardingPersonal,
            (_, s) => const WorkerPersonalDetailsPage(),
          ),
          _page(
            RouteNames.workerOnboardingAadhaar,
            (_, s) => const WorkerAadhaarPage(),
          ),
          _page(RouteNames.workerOnboardingPan, (_, s) => const WorkerPanPage()),
          _page(
            RouteNames.workerOnboardingSelfie,
            (_, s) => const WorkerSelfiePage(),
          ),
          _page(
            RouteNames.workerOnboardingCertificate,
            (_, s) => const WorkerCertificatePage(),
          ),
          _page(
            RouteNames.workerOnboardingSkills,
            (_, s) => const WorkerSkillsPage(),
          ),
          _page(
            RouteNames.workerOnboardingArea,
            (_, s) => const WorkerServiceAreaPage(),
          ),
          _page(
            RouteNames.workerOnboardingWelfare,
            (_, s) => const WorkerWelfarePage(),
          ),
          _page(
            RouteNames.workerOnboardingBank,
            (_, s) => const WorkerBankPage(),
          ),
          _page(
            RouteNames.workerOnboardingStatus,
            (_, s) => const WorkerOnboardingStatusPage(),
          ),
          _page(
            RouteNames.workerOnboardingAvailability,
            (_, s) => const WorkerAvailabilityPage(),
          ),
        ],
      ),

      _page(
        RouteNames.workerIncoming,
        (_, s) => BlocProvider(
          create: (_) => JobFeedCubit()..load(),
          child: const WorkerIncomingOrdersPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.workerJobDetail,
        pageBuilder: (context, state) => transitPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => JobFeedCubit()..load(),
            child: WorkerOrderDetailPage(jobId: state.pathParameters['id']!),
          ),
        ),
      ),
      _page(
        RouteNames.workerActiveJob,
        (_, s) => BlocProvider(
          create: (_) => ActiveJobCubit()..load(),
          child: const WorkerActiveJobPage(),
        ),
      ),
      _page(
        RouteNames.workerNavigation,
        (_, s) => const WorkerNavigationPage(),
      ),
      _page(
        RouteNames.workerAvailability,
        (_, s) => const WorkerAvailabilityStatusPage(),
      ),
      _page(RouteNames.workerEarnings, (_, s) => const WorkerEarningsPage()),
      _page(
        RouteNames.workerReliability,
        (_, s) => const WorkerReliabilityPage(),
      ),

      _page(
        RouteNames.sharedProfile,
        (_, s) => BlocProvider(
          create: (_) => ProfileCubit()..load(),
          child: const ProfileHubPage(),
        ),
      ),
      _page(
        RouteNames.sharedEditProfile,
        (_, s) => BlocProvider(
          create: (_) => ProfileCubit()..load(),
          child: const EditProfilePage(),
        ),
      ),
      _page(RouteNames.sharedSettings, (_, s) => const SettingsPage()),
      _page(
        RouteNames.sharedNotifications,
        (_, s) => BlocProvider(
          create: (_) => NotificationsCubit()..load(),
          child: const NotificationsPage(),
        ),
      ),
      _page(RouteNames.sharedOrderHistory, (_, s) => const OrderHistoryPage()),
      _page(RouteNames.sharedSos, (_, s) => const SosPage()),
      _page(
        RouteNames.sharedSupportChat,
        (_, s) => BlocProvider(
          create: (_) => SupportCubit()..loadChat(),
          child: const SupportChatPage(),
        ),
      ),
      _page(
        RouteNames.sharedSupportTicket,
        (_, s) => BlocProvider(
          create: (_) => SupportCubit(),
          child: const SupportTicketPage(),
        ),
      ),

      GoRoute(
        path: RouteNames.systemState,
        pageBuilder: (context, state) => transitPage(
          key: state.pageKey,
          child: SystemStatePage(typeParam: state.pathParameters['type']!),
        ),
      ),
    ],
  );
}

GoRoute _page(String path, Widget Function(BuildContext, GoRouterState) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => transitPage(
      key: state.pageKey,
      child: builder(context, state),
    ),
  );
}
