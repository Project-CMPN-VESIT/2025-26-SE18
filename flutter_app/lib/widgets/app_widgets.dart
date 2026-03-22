import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

// Reusable PageShell - constrains width like mobile app
class PageShell extends StatelessWidget {
  final Widget child;
  const PageShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: child,
      ),
    );
  }
}

// App Header with optional back button
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? backTo;
  final List<Widget>? rightActions;

  const AppHeader({super.key, required this.title, this.backTo, this.rightActions});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0).withValues(alpha: 0.6))),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Stack(
            children: [
              if (backTo != null)
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), size: 20),
                      onPressed: () => context.go(backTo!),
                    ),
                  ),
                ),
              Center(
                child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: -0.3)),
              ),
              if (rightActions != null)
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Row(mainAxisSize: MainAxisSize.min, children: rightActions!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Gradient colored header (for dashboards)
class ColoredHeader extends StatelessWidget {
  final String title;
  final String? backTo;
  final Widget? child;

  const ColoredHeader({super.key, required this.title, this.backTo, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (backTo != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => context.go(backTo!),
                )
              else
                const SizedBox(width: 40),
              Expanded(
                child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.more_vert, color: Colors.white),
            ],
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// Bottom Navigation Bar
class AppBottomNav extends StatelessWidget {
  final List<NavItem> items;
  final String activePath;

  const AppBottomNav({super.key, required this.items, required this.activePath});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0).withValues(alpha: 0.6))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isActive = item.path == activePath;
              return GestureDetector(
                onTap: () => context.go(item.path),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? item.activeIcon ?? item.icon : item.icon,
                      size: 24,
                      color: isActive ? AppTheme.primary : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? AppTheme.primary : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(width: 128, height: 4, decoration: BoxDecoration(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2),
          )),
        ],
      ),
    );
  }
}

class NavItem {
  final String path;
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NavItem({required this.path, required this.icon, this.activeIcon, required this.label});
}

// Card widget
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

// Status Badge
class StatusBadge extends StatelessWidget {
  final String label;
  final String variant;

  const StatusBadge({super.key, required this.label, this.variant = 'active'});

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(variant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(12)),
      child: Text(label.toUpperCase(), style: TextStyle(color: colors.$2, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  (Color, Color) _getColors(String variant) {
    switch (variant) {
      case 'active' || 'approved':
        return (const Color(0xFFF0FDF4), const Color(0xFF15803D));
      case 'inactive':
        return (const Color(0xFFF1F5F9), const Color(0xFF64748B));
      case 'pending':
        return (const Color(0xFFFFFBEB), const Color(0xFFB45309));
      case 'denied':
        return (const Color(0xFFFEF2F2), const Color(0xFFDC2626));
      case 'teacher':
        return (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8));
      case 'student':
        return (const Color(0xFFFAF5FF), const Color(0xFF7C3AED));
      case 'coordinator':
        return (const Color(0xFFEEF2FF), const Color(0xFF4338CA));
      default:
        return (const Color(0xFFF0FDF4), const Color(0xFF15803D));
    }
  }
}

// Attendance Text with traffic-light colors
class AttendanceText extends StatelessWidget {
  final String value;
  final double fontSize;
  final FontWeight fontWeight;

  const AttendanceText({
    super.key,
    required this.value,
    this.fontSize = 14,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    final double? percent = double.tryParse(value.replaceAll('%', ''));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    if (percent == null) {
      color = isDark ? Colors.white : const Color(0xFF1E293B);
    } else if (percent >= 80) {
      color = const Color(0xFF10B981); // Green
    } else if (percent >= 60) {
      color = Colors.orange; // Orange
    } else {
      color = Colors.red; // Red
    }

    return Text(
      value,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

// Stat Card
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? trend;
  final Color? iconBg;
  final Color? iconColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.trend,
    this.iconBg,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAttendance = value.endsWith('%');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9).withValues(alpha: 0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconBg ?? const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor ?? AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAttendance)
                  AttendanceText(value: value, fontSize: 24)
                else
                  Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ],
            ),
          ),
          if (trend != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 2),
                Text(trend!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
              ],
            ),
        ],
      ),
    );
  }
}

// Action Card (navigation tile)
class ActionCard extends StatelessWidget {
  final String to;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? bgColor;
  final Color? iconColor;
  final int? badgeCount;

  const ActionCard({
    super.key,
    required this.to,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.bgColor,
    this.iconColor,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = bgColor ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final accentColor = iconColor ?? AppTheme.primary;

    return GestureDetector(
      onTap: () => context.go(to),
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 4),
                      Text(subtitle.toUpperCase(), style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Shortcut Link
class ShortcutLink extends StatelessWidget {
  final String to;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconBg;
  final Color? iconColor;

  const ShortcutLink({
    super.key,
    required this.to,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconBg,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.go(to),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconBg ?? const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: iconColor ?? AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B), height: 1.2)),
                  Text(subtitle.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), letterSpacing: 0.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

// Form Field wrapper
class AppFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? hint;
  final String? error;

  const AppFormField({super.key, required this.label, required this.child, this.hint, this.error});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155))),
        ),
        child,
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(children: [
              const Icon(Icons.error, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ]),
          ),
        if (hint != null && error == null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(hint!, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12)),
          ),
      ],
    );
  }
}

// File Upload Zone
class FileUploadZone extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String subtitle;
  final IconData icon;

  const FileUploadZone({super.key, this.onTap, this.title = 'Tap to select a file', this.subtitle = 'Max file size 25MB', this.icon = Icons.upload_file});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155))),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Chip
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const FilterChipWidget({super.key, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
