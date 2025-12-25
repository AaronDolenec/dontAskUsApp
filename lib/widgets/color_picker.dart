import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Color picker widget for avatar selection
class ColorPicker extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String> onColorSelected;
  final List<Color> colors;
  final double itemSize;
  final double spacing;

  const ColorPicker({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
    List<Color>? colors,
    this.itemSize = 44,
    this.spacing = 12,
  }) : colors = colors ?? AppColors.avatarColors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: colors.map((color) {
        final hexColor = AppColors.toHex(color);
        final isSelected = selectedColor?.toUpperCase() == hexColor.toUpperCase();
        
        return GestureDetector(
          onTap: () => onColorSelected(hexColor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}

/// Compact horizontal color picker
class ColorPickerRow extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String> onColorSelected;
  final double itemSize;

  const ColorPickerRow({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
    this.itemSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemSize + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppColors.avatarColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final color = AppColors.avatarColors[index];
          final hexColor = AppColors.toHex(color);
          final isSelected = selectedColor?.toUpperCase() == hexColor.toUpperCase();
          
          return GestureDetector(
            onTap: () => onColorSelected(hexColor),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: itemSize,
              height: itemSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isSelected ? 0.5 : 0.3),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: AppColors.getContrastingTextColor(color),
                      size: itemSize * 0.5,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
