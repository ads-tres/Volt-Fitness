import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/localization/l10n.dart';

/// The dark bar the pages curve down into: icons only, with the QR as a
/// brand-coloured square in the middle, since members open it at the gym
/// door on every visit.
class VoltNavigationBar extends StatelessWidget {
  const VoltNavigationBar({super.key, required this.currentIndex, required this.onSelect});

  /// The QR tab's index; the others sit two on each side.
  static const qrIndex = 2;

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Widget tab(int index, IconData icon, IconData selectedIcon, String label) => _NavItem(
      icon: currentIndex == index ? selectedIcon : icon,
      label: label,
      selected: currentIndex == index,
      onTap: () => onSelect(index),
    );

    return ColoredBox(
      color: AppColors.night,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 84,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              tab(0, Icons.home_outlined, Icons.home_rounded, l10n.navHome),
              tab(1, Icons.card_membership_outlined, Icons.card_membership_rounded, l10n.navMembership),
              _QrButton(label: l10n.navQr, selected: currentIndex == qrIndex, onTap: () => onSelect(qrIndex)),
              tab(3, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, l10n.navPayments),
              tab(4, Icons.person_outline_rounded, Icons.person_rounded, l10n.navProfile),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    excludeSemantics: true,
    child: Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox.square(
          dimension: 52,
          child: Icon(
            icon,
            size: 26,
            color: selected ? context.brand.onNight : Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ),
    ),
  );
}

class _QrButton extends StatelessWidget {
  const _QrButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final radius = BorderRadius.circular(18);
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: brand.primary,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            // A ring shows the QR tab is the open one.
            side: selected ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 60,
              height: 56,
              child: Icon(Icons.qr_code_scanner_rounded, color: brand.onPrimary, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
