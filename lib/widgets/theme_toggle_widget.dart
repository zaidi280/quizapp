import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';
import '../utlis/global.color.dart';

class ThemeToggleWidget extends StatelessWidget {
  final bool showLabel;
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  const ThemeToggleWidget({
    super.key,
    this.showLabel = true,
    this.iconSize = 24,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return GestureDetector(
          onTap: () => themeManager.toggleTheme(),
          child: Container(
            padding: padding ?? const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GlobalColor.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: GlobalColor.getShadowColor(context),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    themeManager.isDarkMode 
                        ? Icons.light_mode 
                        : Icons.dark_mode,
                    key: ValueKey(themeManager.isDarkMode),
                    color: GlobalColor.mainColor,
                    size: iconSize,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    themeManager.isDarkMode ? 'Mode Clair' : 'Mode Sombre',
                    style: TextStyle(
                      color: GlobalColor.getTextPrimaryColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.light_mode,
              color: !themeManager.isDarkMode 
                  ? GlobalColor.mainColor 
                  : GlobalColor.getTextSecondaryColor(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            Switch(
              value: themeManager.isDarkMode,
              onChanged: (value) => themeManager.toggleTheme(),
              activeColor: GlobalColor.mainColor,
              activeTrackColor: GlobalColor.mainColor.withOpacity(0.3),
              inactiveThumbColor: GlobalColor.getTextSecondaryColor(context),
              inactiveTrackColor: GlobalColor.getTextSecondaryColor(context).withOpacity(0.3),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.dark_mode,
              color: themeManager.isDarkMode 
                  ? GlobalColor.mainColor 
                  : GlobalColor.getTextSecondaryColor(context),
              size: 20,
            ),
          ],
        );
      },
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  final String? lightText;
  final String? darkText;
  final bool isCompact;

  const ThemeToggleButton({
    super.key,
    this.lightText,
    this.darkText,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Container(
          decoration: BoxDecoration(
            color: GlobalColor.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
            border: Border.all(
              color: GlobalColor.mainColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Light mode button
              GestureDetector(
                onTap: () => themeManager.setThemeMode(false),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 16,
                    vertical: isCompact ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: !themeManager.isDarkMode 
                        ? GlobalColor.mainColor 
                        : Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isCompact ? 8 : 12),
                      bottomLeft: Radius.circular(isCompact ? 8 : 12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.light_mode,
                        color: !themeManager.isDarkMode 
                            ? Colors.white 
                            : GlobalColor.getTextSecondaryColor(context),
                        size: isCompact ? 16 : 20,
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 8),
                        Text(
                          lightText ?? 'Clair',
                          style: TextStyle(
                            color: !themeManager.isDarkMode 
                                ? Colors.white 
                                : GlobalColor.getTextSecondaryColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Dark mode button
              GestureDetector(
                onTap: () => themeManager.setThemeMode(true),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 16,
                    vertical: isCompact ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: themeManager.isDarkMode 
                        ? GlobalColor.mainColor 
                        : Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(isCompact ? 8 : 12),
                      bottomRight: Radius.circular(isCompact ? 8 : 12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dark_mode,
                        color: themeManager.isDarkMode 
                            ? Colors.white 
                            : GlobalColor.getTextSecondaryColor(context),
                        size: isCompact ? 16 : 20,
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 8),
                        Text(
                          darkText ?? 'Sombre',
                          style: TextStyle(
                            color: themeManager.isDarkMode 
                                ? Colors.white 
                                : GlobalColor.getTextSecondaryColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
