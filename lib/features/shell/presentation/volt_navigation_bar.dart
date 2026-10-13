import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/localization/l10n.dart';

/// Bottom navigation with the QR raised in the middle: it is what members
/// open at the gym door, every visit.
class VoltNavigationBar extends StatelessWidget {
  const VoltNavigationBar({super.key, required this.currentIndex, required this.onSelect});

  /// The QR tab's index; the others sit two on each side.
  static const qrIndex = 2;

  static const _barHeight = 72.0;
  static const _qrSize = 62.0;
  static const _qrRise = 22.0;

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget tab(int index, IconData icon, IconData selectedIcon, String label) => Expanded(
      child: _NavItem(
        icon: currentIndex == index ? selectedIcon : icon,
        label: label,
        selected: currentIndex == index,
        onTap: () => onSelect(index),
      ),
    );

    return SizedBox(
      height: _barHeight + _qrRise + bottomInset,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barHeight + bottomInset,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Color(0x14101828), blurRadius: 24, offset: Offset(0, -6))],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset, left: 8, right: 8),
                child: Row(
                  children: [
                    tab(0, Icons.home_outlined, Icons.home_rounded, l10n.navHome),
                    tab(1, Icons.card_membership_outlined, Icons.card_membership_rounded, l10n.navMembership),
                    const SizedBox(width: _qrSize + 20),
                    tab(3, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, l10n.navPayments),
                    tab(4, Icons.person_outline_rounded, Icons.person_rounded, l10n.navProfile),
                  ],
                ),
              ),
            ),
          ),
          _QrButton(
            label: l10n.navQr,
            selected: currentIndex == qrIndex,
            onTap: () => onSelect(qrIndex),
          ),
        ],
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
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.textTertiary;
    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            // Shrinks a long label ("Membership") a little instead of cutting it.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrButton extends StatelessWidget {
  const _QrButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final (light, deep) = brand.gradient;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: VoltNavigationBar._qrSize,
            height: VoltNavigationBar._qrSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, deep]),
              border: Border.all(color: AppColors.surface, width: 4),
              boxShadow: [BoxShadow(color: deep.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Icon(Icons.qr_code_2_rounded, color: brand.onPrimary, size: 30),
          ),
        ),
      ),
    );
  }
}
