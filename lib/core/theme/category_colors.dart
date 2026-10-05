import 'package:flutter/material.dart';

/// Semantic category colors from the FileVault Stitch design system.
enum FileCategory {
  images,
  videos,
  audio,
  documents,
  downloads,
  apks,
  archives,
  trash,
  folders,
  other,
}

abstract final class CategoryColors {
  static const Color imagesLight = Color(0xFF7C3AED);
  static const Color videosLight = Color(0xFFE11D48);
  static const Color audioLight = Color(0xFFEA580C);
  static const Color documentsLight = Color(0xFF2563EB);
  static const Color downloadsLight = Color(0xFF0B6E99);
  static const Color apksLight = Color(0xFF16A34A);
  static const Color archivesLight = Color(0xFFCA8A04);
  static const Color trashLight = Color(0xFF64748B);

  static const Color imagesDark = Color(0xFFA78BFA);
  static const Color videosDark = Color(0xFFFB7185);
  static const Color audioDark = Color(0xFFFB923C);
  static const Color documentsDark = Color(0xFF60A5FA);
  static const Color downloadsDark = Color(0xFF38BDF8);
  static const Color apksDark = Color(0xFF4ADE80);
  static const Color archivesDark = Color(0xFFFACC15);
  static const Color trashDark = Color(0xFF94A3B8);

  static Color ink(Brightness brightness, FileCategory category) {
    final bool dark = brightness == Brightness.dark;
    return switch (category) {
      FileCategory.images => dark ? imagesDark : imagesLight,
      FileCategory.videos => dark ? videosDark : videosLight,
      FileCategory.audio => dark ? audioDark : audioLight,
      FileCategory.documents => dark ? documentsDark : documentsLight,
      FileCategory.downloads || FileCategory.folders =>
        dark ? downloadsDark : downloadsLight,
      FileCategory.apks => dark ? apksDark : apksLight,
      FileCategory.archives => dark ? archivesDark : archivesLight,
      FileCategory.trash || FileCategory.other =>
        dark ? trashDark : trashLight,
    };
  }

  static Color container(Brightness brightness, FileCategory category) {
    return ink(brightness, category).withValues(alpha: darkAlpha(brightness));
  }

  static double darkAlpha(Brightness brightness) {
    return brightness == Brightness.dark ? 0.16 : 0.12;
  }
}
