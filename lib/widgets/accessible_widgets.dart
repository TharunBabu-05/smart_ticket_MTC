import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../services/accessibility_service.dart';

/// Accessible Button with proper semantics
class AccessibleElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? semanticHint;
  final IconData? icon;
  final bool isLoading;

  const AccessibleElevatedButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.semanticLabel,
    this.semanticHint,
    this.icon,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? text,
      hint: semanticHint ?? (onPressed != null ? 'Double tap to activate' : 'Button disabled'),
      button: true,
      enabled: onPressed != null && !isLoading,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(88, 48), // Minimum tap target size
        ),
      ),
    );
  }
}

/// Accessible Text Button with proper semantics
class AccessibleTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? semanticHint;
  final IconData? icon;

  const AccessibleTextButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.semanticLabel,
    this.semanticHint,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? text,
      hint: semanticHint ?? (onPressed != null ? 'Double tap to activate' : 'Button disabled'),
      button: true,
      enabled: onPressed != null,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(text),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(88, 48),
        ),
      ),
    );
  }
}

/// Accessible Text Field with proper semantics
class AccessibleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? semanticLabel;
  final String? semanticHint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const AccessibleTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.semanticLabel,
    this.semanticHint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? labelText,
      hint: semanticHint ?? 'Text field. ${hintText ?? ''}',
      textField: true,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

/// Accessible Card with proper semantics
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const AccessibleCard({
    Key? key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint ?? (onTap != null ? 'Double tap to open' : null),
      button: onTap != null,
      child: Card(
        margin: margin ?? const EdgeInsets.all(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Accessible Icon Button with proper semantics
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final double? iconSize;
  final Color? color;

  const AccessibleIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.iconSize,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint ?? 'Button. Double tap to activate',
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        iconSize: iconSize ?? 24,
        color: color,
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
      ),
    );
  }
}

/// Accessible List Tile with proper semantics
class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;

  const AccessibleListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint ?? (onTap != null ? 'List item. Double tap to select' : 'List item'),
      button: onTap != null,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}

/// Accessible Switch with proper semantics
class AccessibleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final String? semanticLabel;

  const AccessibleSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '$label switch',
      hint: value ? '$label is enabled' : '$label is disabled',
      toggled: value,
      child: SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

/// Accessible Slider with proper semantics
class AccessibleSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final String? semanticLabel;

  const AccessibleSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.label,
    this.divisions,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '$label slider',
      hint: 'Current value: ${value.toStringAsFixed(1)}. Swipe up or down to adjust',
      slider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }
}

/// Screen Reader Announcer Widget
class ScreenReaderAnnouncer extends StatelessWidget {
  final String message;
  final Widget child;
  final bool announceOnBuild;

  const ScreenReaderAnnouncer({
    Key? key,
    required this.message,
    required this.child,
    this.announceOnBuild = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (announceOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SemanticsService.announce(message, TextDirection.ltr);
      });
    }
    
    return child;
  }
}

/// Focus Trap for modal dialogs
class AccessibleDialog extends StatefulWidget {
  final Widget child;
  final String? semanticLabel;
  final bool barrierDismissible;

  const AccessibleDialog({
    Key? key,
    required this.child,
    this.semanticLabel,
    this.barrierDismissible = true,
  }) : super(key: key);

  @override
  State<AccessibleDialog> createState() => _AccessibleDialogState();
}

class _AccessibleDialogState extends State<AccessibleDialog> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    // Announce dialog opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      SemanticsService.announce(
        'Dialog opened. ${widget.semanticLabel ?? 'Use back button to close'}',
        TextDirection.ltr,
      );
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: AlertDialog(
        content: widget.child,
        semanticLabel: widget.semanticLabel,
      ),
    );
  }
}