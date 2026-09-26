import 'package:go_router/go_router.dart';

import '../../features/farms/presentation/screens/farm_map_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'farmMap',
      builder: (context, state) => const FarmMapScreen(),
    ),
  ],
);