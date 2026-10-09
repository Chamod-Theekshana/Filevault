import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/utils/ui_overlays.dart';
import 'package:filevault/core/widgets/main_shell.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/features/analyzer/analyzer_view.dart';
import 'package:filevault/features/analyzer/cleanup_views.dart';
import 'package:filevault/features/archive/archive_view.dart';
import 'package:filevault/features/browser/browser_view.dart';
import 'package:filevault/features/category/category_view.dart';
import 'package:filevault/features/collections/collections_views.dart';
import 'package:filevault/features/home/home_view.dart';
import 'package:filevault/features/onboarding/onboarding_view.dart';
import 'package:filevault/features/onboarding/splash_view.dart';
import 'package:filevault/features/operations/operations_view.dart';
import 'package:filevault/features/search/search_view.dart';
import 'package:filevault/features/security/app_lock_setup_view.dart';
import 'package:filevault/features/settings/settings_view.dart';
import 'package:filevault/features/trash/trash_view.dart';
import 'package:filevault/features/vault/vault_setup_view.dart';
import 'package:filevault/features/vault/vault_view.dart';
import 'package:filevault/features/viewer/apk_info_view.dart';
import 'package:filevault/features/viewer/audio_player_view.dart';
import 'package:filevault/features/viewer/image_viewer_view.dart';
import 'package:filevault/features/viewer/pdf_viewer_view.dart';
import 'package:filevault/features/viewer/text_editor_view.dart';
import 'package:filevault/features/viewer/video_player_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellKey = GlobalKey<NavigatorState>();

String _pathParam(GoRouterState state) =>
    state.uri.queryParameters['path'] ?? AppConstants.primaryStoragePath;

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    observers: <NavigatorObserver>[PopupTracker()],
    routes: <RouteBase>[
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashView()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingView()),

      // Bottom-navigation branches.
      StatefulShellRoute.indexedStack(
        builder: (_, _, StatefulNavigationShell shell) => MainShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _shellKey,
            observers: <NavigatorObserver>[PopupTracker()],
            routes: <RouteBase>[
              GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeView()),
            ],
          ),
          StatefulShellBranch(
            observers: <NavigatorObserver>[PopupTracker()],
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.browse,
                builder: (_, GoRouterState state) => BrowserView(path: _pathParam(state)),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: <NavigatorObserver>[PopupTracker()],
            routes: <RouteBase>[
              GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchView()),
            ],
          ),
          StatefulShellBranch(
            observers: <NavigatorObserver>[PopupTracker()],
            routes: <RouteBase>[
              GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsView()),
            ],
          ),
        ],
      ),

      // Full-screen routes pushed above the shell.
      GoRoute(
        path: AppRoutes.category,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) => CategoryView(
          category: FileCategory.fromName(state.uri.queryParameters['category']),
        ),
      ),
      GoRoute(
        path: AppRoutes.trash,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const TrashView(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const FavoritesView(),
      ),
      GoRoute(
        path: AppRoutes.recents,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const RecentsView(),
      ),
      GoRoute(
        path: AppRoutes.tags,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const TagsView(),
      ),
      GoRoute(
        path: AppRoutes.operations,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const OperationsView(),
      ),
      GoRoute(
        path: AppRoutes.analyzer,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const AnalyzerView(),
        routes: <RouteBase>[
          GoRoute(
            path: 'large',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const LargeFilesView(),
          ),
          GoRoute(
            path: 'duplicates',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const DuplicatesView(),
          ),
          GoRoute(
            path: 'junk',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const JunkCleanerView(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.archive,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) => ArchiveView(path: _pathParam(state)),
      ),
      GoRoute(
        path: AppRoutes.vault,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) {
          final Map<String, Object?>? extra = state.extra as Map<String, Object?>?;
          final List<Object?> pending =
              (extra?['pendingAdd'] as List<Object?>?) ?? const <Object?>[];
          return VaultView(
            pendingAdd: pending.map((Object? e) => e.toString()).toList(growable: false),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'setup',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const VaultSetupView(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.appLockSetup,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) {
          final Map<String, Object?>? extra = state.extra as Map<String, Object?>?;
          return AppLockSetupView(changeOnly: extra?['changeOnly'] == true);
        },
      ),
      GoRoute(
        path: AppRoutes.imageViewer,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) {
          final Map<String, Object?>? extra = state.extra as Map<String, Object?>?;
          final List<FileEntry> siblings =
              (extra?['siblings'] as List<FileEntry>?) ?? const <FileEntry>[];
          final int index = (extra?['index'] as int?) ?? 0;
          return ImageViewerView(
            entries: siblings.isEmpty ? <FileEntry>[] : siblings,
            initialIndex: index,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.videoViewer,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) => VideoPlayerView(path: _pathParam(state)),
      ),
      GoRoute(
        path: AppRoutes.audioPlayer,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) {
          final Map<String, Object?>? extra = state.extra as Map<String, Object?>?;
          final List<FileEntry> queue = (extra?['queue'] as List<FileEntry>?) ?? const <FileEntry>[];
          final String path = _pathParam(state);
          final int index = queue.indexWhere((FileEntry e) => e.path == path);
          return AudioPlayerView(queue: queue, initialIndex: index < 0 ? 0 : index);
        },
      ),
      GoRoute(
        path: AppRoutes.textEditor,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) => TextEditorView(path: _pathParam(state)),
      ),
      GoRoute(
        path: AppRoutes.pdfViewer,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) => PdfViewerView(path: _pathParam(state)),
      ),
      GoRoute(
        path: AppRoutes.apkInfo,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, GoRouterState state) => ApkInfoView(path: _pathParam(state)),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(child: Text(state.error?.message ?? 'Route not found')),
    ),
  );
});
