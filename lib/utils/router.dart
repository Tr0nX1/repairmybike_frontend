import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/app_state.dart';
import '../ui/landing_page.dart';
import '../ui/flash_page.dart';
import '../ui/auth_page.dart';
import '../ui/main_shell.dart';
import '../ui/home_page.dart';
import '../ui/search_page.dart';
import '../ui/cart_page.dart';
import '../ui/booking_list_page.dart';
import '../ui/profile_page.dart';
import '../ui/policy_page.dart';
import '../ui/vehicle_type_page.dart';
import '../ui/vehicle_brand_page.dart';
import '../ui/vehicle_name_page.dart';
import '../ui/your_vehicle_page.dart';
import '../ui/notifications_page.dart';
import '../ui/services_page.dart';
import '../ui/quick_service_detail_page.dart';
import '../ui/quick_service_history_page.dart';
import '../ui/spare_parts_page.dart';
import '../ui/membership_detail_page.dart'; 
import '../ui/service_detail_page.dart';
import '../ui/profile_details_page.dart';
import '../ui/saved_services_page.dart';
import '../ui/my_subscriptions_page.dart';
import '../ui/customer_care_page.dart';
import '../ui/subscription_section.dart';
import '../models/service.dart';
import '../models/subscription.dart';
import '../ui/not_found_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Whether AppState has been loaded from disk in this session.
bool _appStateInitialized = false;

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => NotFoundPage(state: state),
  redirect: (context, state) async {
    // Initialize AppState from local storage once per session
    if (!_appStateInitialized) {
      await AppState.init();
      _appStateInitialized = true;
    }

    final isAuthenticated = AppState.isAuthenticated;
    final location = state.uri.toString();

    // Authenticated users on the landing page get redirected to the app
    if (location == '/' && isAuthenticated) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const FlashPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    
    // Vehicle Selection Flow
    GoRoute(
      path: '/vehicle-type',
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'];
        return VehicleTypePage(phone: phone);
      },
    ),
    GoRoute(
      path: '/vehicle-brand',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final phone = extra?['phone'] as String?;
        final vehicleTypeId = extra?['vehicleTypeId'] as int? ?? 0;
        final vehicleTypeName = extra?['vehicleTypeName'] as String? ?? '';
        return VehicleBrandPage(
          phone: phone,
          vehicleTypeId: vehicleTypeId,
          vehicleTypeName: vehicleTypeName,
        );
      },
    ),
    GoRoute(
      path: '/vehicle-name',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final phone = extra?['phone'] as String?;
        final vehicleTypeId = extra?['vehicleTypeId'] as int? ?? 0;
        final vehicleTypeName = extra?['vehicleTypeName'] as String? ?? '';
        final brandId = extra?['brandId'] as int? ?? 0;
        final brandName = extra?['brandName'] as String? ?? '';
        return VehicleNamePage(
          phone: phone,
          vehicleTypeId: vehicleTypeId,
          vehicleTypeName: vehicleTypeName,
          brandId: brandId,
          brandName: brandName,
        );
      },
    ),
    GoRoute(
      path: '/your-vehicle',
      builder: (context, state) => const YourVehiclePage(),
    ),
    
    // Shell Route for Main Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookings',
              builder: (context, state) => const BookingListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),

    // App Pages
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/services',
      builder: (context, state) {
        final categoryId = int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
        final categoryName = state.uri.queryParameters['name'] ?? '';
        return ServicesPage(categoryId: categoryId, categoryName: categoryName);
      },
    ),
    GoRoute(
      path: '/quick-service',
      builder: (context, state) => const QuickServiceDetailsPage(),
    ),
    GoRoute(
      path: '/quick-service-history',
      builder: (context, state) => const QuickServiceHistoryPage(),
    ),
    GoRoute(
      path: '/spare-parts',
      builder: (context, state) => const SparePartsPage(),
    ),
    GoRoute(
      path: '/subscriptions',
      builder: (context, state) => const SubscriptionsPage(),
    ),
    GoRoute(
      path: '/membership-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final tierName = extra?['tierName'] as String? ?? '';
        final options = extra?['options'] as List<SubscriptionPlan>? ?? [];
        return MembershipDetailPage(tierName: tierName, options: options);
      },
    ),
    GoRoute(
      path: '/my-subscriptions',
      builder: (context, state) => const MySubscriptionsPage(),
    ),
    GoRoute(
      path: '/service-detail',
      builder: (context, state) {
        final service = state.extra as Service?;
        if (service != null) {
          return ServiceDetailPage(service: service);
        }
        return const Scaffold(body: Center(child: Text('Service not found')));
      },
    ),
    GoRoute(
      path: '/profile-details',
      builder: (context, state) => const ProfileDetailsPage(popOnSave: true),
    ),
    GoRoute(
      path: '/saved-services',
      builder: (context, state) => const SavedServicesPage(),
    ),
    GoRoute(
      path: '/customer-care',
      builder: (context, state) => const CustomerCarePage(),
    ),

    // Policy Routes
    GoRoute(
      path: '/terms',
      builder: (context, state) => const PolicyPage(
        slug: 'terms-and-conditions',
        title: 'Terms & Conditions',
      ),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PolicyPage(
        slug: 'privacy-policy',
        title: 'Privacy Policy',
      ),
    ),
    GoRoute(
      path: '/refund',
      builder: (context, state) => const PolicyPage(
        slug: 'refund-and-cancellation-policy',
        title: 'Refund & Cancellation',
      ),
    ),
    GoRoute(
      path: '/shipping',
      builder: (context, state) => const PolicyPage(
        slug: 'shipping-and-delivery-policy',
        title: 'Shipping & Delivery',
      ),
    ),
    GoRoute(
      path: '/payment-policy',
      builder: (context, state) => const PolicyPage(
        slug: 'payment-policy',
        title: 'Payment Policy',
      ),
    ),
    GoRoute(
      path: '/service-policy',
      builder: (context, state) => const PolicyPage(
        slug: 'service-policy',
        title: 'Service Policy',
      ),
    ),
  ],
);
