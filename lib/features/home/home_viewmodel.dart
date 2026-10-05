import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/domain/models/file_entity.dart';
import 'package:filevault/features/home/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<HomeViewModel, HomeState> homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    return HomeState(
      volumes: const <StorageVolumeInfo>[
        StorageVolumeInfo(
          id: 'internal',
          name: 'Internal storage',
          path: '/storage/emulated/0',
          totalBytes: 0,
          usedBytes: 0,
          isPrimary: true,
          kind: StorageVolumeKind.internal,
        ),
      ],
      categories: FileCategory.values
          .where((FileCategory c) =>
              c != FileCategory.folders && c != FileCategory.other)
          .map(
            (FileCategory c) => CategorySummary(
              category: c,
              itemCount: 0,
              totalBytes: 0,
            ),
          )
          .toList(growable: false),
      recents: const <FileEntity>[],
      quickAccess: const <QuickAccessItem>[
        QuickAccessItem(
          id: 'downloads',
          title: 'Downloads',
          subtitle: '/storage/emulated/0/Download',
          count: 0,
          category: FileCategory.downloads,
          icon: 'download',
        ),
        QuickAccessItem(
          id: 'camera',
          title: 'Camera',
          subtitle: 'DCIM/Camera',
          count: 0,
          category: FileCategory.images,
          icon: 'camera',
        ),
        QuickAccessItem(
          id: 'whatsapp',
          title: 'WhatsApp',
          subtitle: 'Android/media/com.whatsapp',
          count: 0,
          category: FileCategory.folders,
          icon: 'chat',
        ),
        QuickAccessItem(
          id: 'screenshots',
          title: 'Screenshots',
          subtitle: 'Pictures/Screenshots',
          count: 0,
          category: FileCategory.images,
          icon: 'screenshot',
        ),
      ],
    );
  }
}
