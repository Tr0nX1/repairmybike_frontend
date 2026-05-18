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
import '../ui/booking_detail_page.dart';
import '../ui/booking_confirmation_page.dart';
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

// Management Imports
import '../ui/management/mechanic/mechanic_dashboard.dart';
import '../ui/management/staff/staff_dashboard.dart';
import '../ui/management/admin/admin_dashboard.dart';
import '../ui/management/admin/inventory_panel.dart';
import '../ui/management/admin/financial_dashboard.dart';
import '../ui/management/admin/cms_panel.dart';
import '../ui/management/admin/staff_directory_page.dart';
import '../ui/management/admin/pricing_editor_page.dart';
import '../ui/management/admin/audit_log_page.dart';
import '../ui/management/mechanic/job_detail_screen.dart';
import '../ui/management/staff/walk_in_creator_page.dart';
import '../ui/management/staff/logistics_dashboard.dart';
import '../ui/management/staff/handover_form_page.dart';
import '../ui/management/staff/crm_panel_page.dart';
import '../ui/management/staff/cash_reconciliation_page.dart';
import '../ui/staff/cash/cash_session_screen.dart';
import '../ui/addresses_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Whether AppState has been loaded from disk in this session.
bool _appStateInitialized = false;

const Set<String> _publicRoutes = {
  '/',
  '/auth',
  '/splash',
  '/terms-and-conditions',
  '/privacy-policy',
  '/refund-and-cancellation-policy',
  '/shipping-and-delivery-policy',
  '/payment-policy',
  '/service-policy',
  '/terms',
  '/privacy',
  '/refund',
  '/shipping',
};

bool _isPublicRoute(String location) {
  final path = Uri.parse(location).path;
  return _publicRoutes.contains(path);
}

Map<String, dynamic>? _extraMap(Object? extra) {
  if (extra is Map<String, dynamic>) return extra;
  if (extra is Map) {
    return {
      for (final entry in extra.entries) entry.key.toString(): entry.value,
    };
  }
  return null;
}

int _extraInt(Map<String, dynamic>? extra, String key) {
  final value = extra?[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

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
    final isStaff = AppState.isStaff;
    final location = state.uri.toString();

    // Not authenticated? Allow only public routes
    if (!isAuthenticated) {
      if (_isPublicRoute(location)) return null;
      return '/auth';
    }

    // AUTHENTICATED REDIRECTIONS

    // 1. Authenticated users on public login/landing pages
    if (location == '/' || location == '/auth') {
      return isStaff ? '/staff' : '/home';
    }

    // 2. Prevent staff from accessing customer home/shell
    if (isStaff && (location.startsWith('/home') || location.startsWith('/search') || location.startsWith('/cart') || location.startsWith('/bookings') || location.startsWith('/profile'))) {
      return '/staff';
    }

    // 3. Prevent customers from accessing management routes
    if (!isStaff && (location.startsWith('/mechanic') || location.startsWith('/staff') || location.startsWith('/admin'))) {
      return '/home';
    }

    return null;
  },
  routes: [
    // --- Management Routes ---
    GoRoute(
      path: '/mechanic',
      builder: (context, state) => const MechanicDashboardPage(),
      routes: [
        GoRoute(
          path: 'job/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return JobDetailScreen(bookingId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const StaffDashboardPage(),
      routes: [
        GoRoute(
          path: 'walk-in',
          builder: (context, state) => const WalkInCreatorPage(),
        ),
        GoRoute(
          path: 'logistics',
          builder: (context, state) => const LogisticsDashboardPage(),
        ),
        GoRoute(
          path: 'handover/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return HandoverFormPage(bookingId: id);
          },
        ),
        GoRoute(
          path: 'crm',
          builder: (context, state) => const CrmPanelPage(),
        ),
        GoRoute(
          path: 'reconciliation',
          builder: (context, state) => const CashReconciliationPage(),
        ),
        GoRoute(
          path: 'cash',
          builder: (context, state) => const CashSessionScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
      routes: [
        GoRoute(
          path: 'staff',
          builder: (context, state) => const StaffDirectoryPage(),
        ),
        GoRoute(
          path: 'cms',
          builder: (context, state) => const CmsPanelPage(),
        ),
        GoRoute(
          path: 'pricing',
          builder: (context, state) => const PricingEditorPage(),
        ),
        GoRoute(
          path: 'inventory',
          builder: (context, state) => const InventoryPanel(),
        ),
        GoRoute(
          path: 'financial',
          builder: (context, state) => const FinancialDashboardPage(),
        ),
        GoRoute(
          path: 'audit-logs',
          builder: (context, state) => const AuditLogPage(),
        ),
      ],
    ),

    // --- Aliases for shortened paths (Prevent 404s) ---
    GoRoute(
      path: '/terms',
      redirect: (context, state) => '/terms-and-conditions',
    ),
    GoRoute(
      path: '/privacy',
      redirect: (context, state) => '/privacy-policy',
    ),
    GoRoute(
      path: '/refund',
      redirect: (context, state) => '/refund-and-cancellation-policy',
    ),
    GoRoute(
      path: '/shipping',
      redirect: (context, state) => '/shipping-and-delivery-policy',
    ),
    // ------------------------------------------------

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
        final extra = _extraMap(state.extra);
        final phone = extra?['phone']?.toString();
        final vehicleTypeId = _extraInt(extra, 'vehicleTypeId');
        final vehicleTypeName = extra?['vehicleTypeName']?.toString() ?? '';
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
        final extra = _extraMap(state.extra);
        final phone = extra?['phone']?.toString();
        final vehicleTypeId = _extraInt(extra, 'vehicleTypeId');
        final vehicleTypeName = extra?['vehicleTypeName']?.toString() ?? '';
        final brandId = _extraInt(extra, 'brandId');
        final brandName = extra?['brandName']?.toString() ?? '';
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
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return BookingDetailPage(bookingId: id);
                  },
                ),
              ],
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
      path: '/booking-confirmation',
      builder: (context, state) {
        final booking = _extraMap(state.extra);
        if (booking == null) return const Scaffold(body: Center(child: Text('Invalid booking data')));
        return BookingConfirmationPage(booking: booking);
      },
    ),
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
        final extra = _extraMap(state.extra);
        final tierName = extra?['tierName']?.toString() ?? '';
        final rawOptions = extra?['options'];
        final options = rawOptions is List<SubscriptionPlan> ? rawOptions : <SubscriptionPlan>[];
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
        final service = state.extra is Service ? state.extra as Service : null;
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
      path: '/addresses',
      builder: (context, state) => const AddressesPage(),
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
      path: '/terms-and-conditions',
      builder: (context, state) => const PolicyPage(
        slug: 'terms-and-conditions',
        title: 'Terms & Conditions',
      ),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PolicyPage(
        slug: 'privacy-policy',
        title: 'Privacy Policy',
      ),
    ),
    GoRoute(
      path: '/refund-and-cancellation-policy',
      builder: (context, state) => const PolicyPage(
        slug: 'refund-and-cancellation-policy',
        title: 'Refund & Cancellation Policy',
      ),
    ),
    GoRoute(
      path: '/shipping-and-delivery-policy',
      builder: (context, state) => const PolicyPage(
        slug: 'shipping-and-delivery-policy',
        title: 'Shipping & Delivery Policy',
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
