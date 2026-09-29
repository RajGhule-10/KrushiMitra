import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/screens/auth_gate.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/farmer_profile/presentation/screens/farmer_profile_screen.dart';
import '../../features/farms/presentation/screens/farm_map_screen.dart';
import '../../features/farms/presentation/screens/create_farm_screen.dart';
import '../../features/farms/presentation/screens/farms_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'authGate',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const FarmerProfileScreen(),
    ),
    GoRoute(
      path: '/farms',
      name: 'farms',
      builder: (context, state) => const FarmsScreen(),
    ),
    GoRoute(
      path: '/farms/create',
      name: 'createFarm',
      builder: (context, state) => const CreateFarmScreen(),
    ),
    GoRoute(
      path: '/farm-map',
      name: 'farmMap',
      builder: (context, state) => const FarmMapScreen(),
    ),
  ],
);
