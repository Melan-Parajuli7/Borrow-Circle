import 'package:flutter/material.dart';

import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/model/item_model.dart';

// =====================================================================
//  Reusable building blocks used by many pages.
//  If you want to change how buttons / tags / cards look, change them here.
// =====================================================================

/// App logo. Put your logo at assets/images/logo.png (see notes) - until then an icon is shown.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: size * 0.09),
        ),
        child: Icon(Icons.swap_horiz_rounded, color: AppColors.secondary, size: size * 0.5),
      ),
    );
  }
}

/// Labelled text box (label above, like the Figma).
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? suffixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _hidden,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLength: widget.maxLength,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textGrey),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : (widget.suffixIcon == null ? null : Icon(widget.suffixIcon, color: AppColors.textGrey)),
          ),
        ),
      ],
    );
  }
}

/// Big green button. Shows a spinner and ignores taps while [isLoading].
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
                Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}

/// Small message at the bottom of the screen.
void showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
}

/// Rounded square back button from the Figma.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.maybePop(context),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.arrow_back, color: AppColors.textDark),
      ),
    );
  }
}

/// Top bar of every screen: [back button] Title ............ [trailing]
class ScreenHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;

  const ScreenHeader({super.key, required this.title, this.showBack = true, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          if (showBack) ...[const AppBackButton(), const SizedBox(width: 14)],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small square icon button (filter, calendar, bell...).
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const SquareIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

/// Small rounded label, e.g. "Peer item".
class PillTag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;

  const PillTag({
    super.key,
    required this.text,
    this.icon,
    this.bg = AppColors.primaryLight,
    this.fg = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 5)],
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Status chip for requests and loans ("Pending", "Approved", "On loan"...).
class StatusChip extends StatelessWidget {
  final String status;
  final String? textOverride;
  const StatusChip({super.key, required this.status, this.textOverride});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.statusColors(status);
    return PillTag(text: textOverride ?? AppStatic.pretty(status), bg: bg, fg: fg);
  }
}

/// Image from the backend with a placeholder when missing / loading / broken.
class NetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  const NetImage({super.key, required this.url, this.width, this.height, this.radius = 14, this.fit = BoxFit.cover});

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.primaryLight,
        child: const Icon(Icons.image_outlined, color: AppColors.primaryLightActive, size: 36),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? _placeholder()
          : Image.network(
              url!,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => _placeholder(),
              loadingBuilder: (context, child, progress) => progress == null ? child : _placeholder(),
            ),
    );
  }
}

/// Round profile picture, or the user's initials when there is no picture.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? avatar;
  final double radius;
  const UserAvatar({super.key, required this.name, this.avatar, this.radius = 26});

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final url = AppStatic.avatarUrl(avatar);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLightActive.withValues(alpha: 0.6),
      backgroundImage: url == null ? null : NetworkImage(url),
      child: url == null
          ? Text(initialsOf(name),
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: radius * 0.7))
          : null,
    );
  }
}

/// The "All items | Peer items | Group items" style switch.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const SegmentedTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: i == selected ? AppColors.primary : AppColors.textGrey,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Ready to borrow ............. See all"
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionText!,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
      ],
    );
  }
}

/// Light green information box with a shield icon.
class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color bg;
  final Color fg;
  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.verified_user_outlined,
    this.bg = AppColors.primaryLight,
    this.fg = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 15, height: 1.35))),
        ],
      ),
    );
  }
}

/// Shown when a list is empty.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Shown when loading failed. Has a Try again button.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Something went wrong',
      message: message,
      action: SizedBox(
        width: 160,
        child: OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ),
    );
  }
}

/// 5 stars. Pass [onChanged] to make them tappable.
class StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;
  const StarRating({super.key, required this.rating, this.size = 28, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i <= rating ? AppColors.primary : AppColors.primaryLightActive,
              ),
            ),
          ),
      ],
    );
  }
}

/// Item card used in the Home / See all grids.
class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onTap;
  const ItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final who = item.isGroupItem ? (item.groupName ?? 'Group') : item.ownerName;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetImage(url: AppStatic.imageUrl(item.imageUrl), height: 125, width: double.infinity, radius: 14),
            const SizedBox(height: 10),
            PillTag(
              text: item.isGroupItem ? 'Group item' : 'Peer item',
              icon: item.isGroupItem ? Icons.groups_outlined : Icons.person_outline,
            ),
            const SizedBox(height: 8),
            Text(item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 3),
            Text('$who \u00b7 ${item.isAvailable ? 'Available' : 'On loan'}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 3),
            Text(item.category ?? 'Other',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// White bordered box with rounded corners. Used for most cards.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor ?? AppColors.border),
        ),
        child: child,
      ),
    );
  }
}
