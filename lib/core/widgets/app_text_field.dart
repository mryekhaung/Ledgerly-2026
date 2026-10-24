import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveTextField, AdaptiveTextFormField;
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// A text field that uses adaptive platform styling while retaining the app's
/// Material decoration on Android and web.
class AppTextField extends StatelessWidget {
  /// Creates a text field.
  const AppTextField({
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.cursorColor,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.autocorrect = true,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.cupertinoDecoration,
    super.key,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Defines the keyboard focus for this field.
  final FocusNode? focusNode;

  /// Material decoration and the label, hint, prefix, suffix, and errors used
  /// to build the iOS field.
  final InputDecoration decoration;

  /// The type of keyboard to use for editing the text.
  final TextInputType? keyboardType;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// Configures how the platform keyboard capitalizes text.
  final TextCapitalization textCapitalization;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// The color to use for the text cursor on Material platforms.
  final Color? cursorColor;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The maximum number of lines to show at one time.
  final int? maxLines;

  /// The minimum number of lines to occupy.
  final int? minLines;

  /// The maximum number of characters to allow.
  final int? maxLength;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether to enable autocorrection.
  final bool autocorrect;

  /// Whether this field should focus itself if nothing else is focused.
  final bool autofocus;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Called when the user changes the text.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the text.
  final ValueChanged<String>? onSubmitted;

  /// Called when the user taps the field.
  final VoidCallback? onTap;

  /// Optional input validation and formatting overrides.
  final List<TextInputFormatter>? inputFormatters;

  /// Optional iOS decoration override, such as a transparent field inside a
  /// separately decorated surface.
  final BoxDecoration? cupertinoDecoration;

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.resolve().usesCupertino) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        style: style,
        cursorColor: cursorColor,
        textAlign: textAlign,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        obscureText: obscureText,
        autocorrect: autocorrect,
        autofocus: autofocus,
        enabled: enabled,
        readOnly: readOnly,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        inputFormatters: inputFormatters,
        decoration: decoration,
      );
    }

    final colors = AppThemeColors.of(context);
    final label =
        decoration.label ??
        (decoration.labelText == null ? null : Text(decoration.labelText!));
    final errorText = decoration.errorText;
    final backgroundColor = decoration.filled == true
        ? decoration.fillColor ?? colors.surfaceSubtle
        : colors.surfaceRaised;
    final field = AdaptiveTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: decoration.hintText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      obscureText: obscureText,
      autocorrect: autocorrect,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      inputFormatters: inputFormatters,
      padding:
          decoration.contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
      prefix:
          decoration.prefix ??
          decoration.prefixIcon ??
          _decorationText(decoration.prefixText, decoration.prefixStyle),
      suffix:
          decoration.suffix ??
          decoration.suffixIcon ??
          _decorationText(decoration.suffixText, decoration.suffixStyle),
      cupertinoDecoration:
          cupertinoDecoration ??
          BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: errorText == null ? colors.border : colors.warning,
              width: errorText == null ? 0.5 : 1,
            ),
            borderRadius: AppRadius.borderMd,
          ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          DefaultTextStyle(
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
            child: label,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        field,
        if (errorText != null || decoration.helperText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText ?? decoration.helperText!,
            style: AppTypography.caption.copyWith(
              color: errorText == null ? colors.textSecondary : colors.warning,
            ),
          ),
        ],
      ],
    );
  }
}

/// A validated text field with platform-adaptive styling.
class AppTextFormField extends StatelessWidget {
  /// Creates a validated text field.
  const AppTextFormField({
    this.controller,
    this.focusNode,
    this.initialValue,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.autocorrect = true,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.onSaved,
    this.validator,
    this.inputFormatters,
    this.autovalidateMode,
    this.cupertinoDecoration,
    super.key,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Defines the keyboard focus for this field.
  final FocusNode? focusNode;

  /// The initial value when no controller is supplied.
  final String? initialValue;

  /// Material decoration and the label, hint, prefix, suffix, and errors used
  /// to build the iOS field.
  final InputDecoration decoration;

  /// The type of keyboard to use for editing the text.
  final TextInputType? keyboardType;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// Configures how the platform keyboard capitalizes text.
  final TextCapitalization textCapitalization;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The maximum number of lines to show at one time.
  final int? maxLines;

  /// The minimum number of lines to occupy.
  final int? minLines;

  /// The maximum number of characters to allow.
  final int? maxLength;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether to enable autocorrection.
  final bool autocorrect;

  /// Whether this field should focus itself if nothing else is focused.
  final bool autofocus;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Called when the user changes the text.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the text.
  final ValueChanged<String>? onFieldSubmitted;

  /// Called when the user taps the field.
  final VoidCallback? onTap;

  /// Called when the form is saved.
  final FormFieldSetter<String>? onSaved;

  /// Validates the field.
  final FormFieldValidator<String>? validator;

  /// Optional input validation and formatting overrides.
  final List<TextInputFormatter>? inputFormatters;

  /// Controls when this field validates itself.
  final AutovalidateMode? autovalidateMode;

  /// Optional iOS decoration override.
  final BoxDecoration? cupertinoDecoration;

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.resolve().usesCupertino) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        initialValue: initialValue,
        decoration: decoration,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        obscureText: obscureText,
        autocorrect: autocorrect,
        autofocus: autofocus,
        enabled: enabled,
        readOnly: readOnly,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        onTap: onTap,
        onSaved: onSaved,
        validator: validator,
        inputFormatters: inputFormatters,
        autovalidateMode: autovalidateMode,
      );
    }

    final colors = AppThemeColors.of(context);
    final label =
        decoration.label ??
        (decoration.labelText == null ? null : Text(decoration.labelText!));
    final errorText = decoration.errorText;
    final backgroundColor = decoration.filled == true
        ? decoration.fillColor ?? colors.surfaceSubtle
        : colors.surfaceRaised;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          DefaultTextStyle(
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
            child: label,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        AdaptiveTextFormField(
          controller: controller,
          focusNode: focusNode,
          initialValue: initialValue,
          placeholder: decoration.hintText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          obscureText: obscureText,
          autocorrect: autocorrect,
          autofocus: autofocus,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          onSubmitted: onFieldSubmitted,
          onTap: onTap,
          onSaved: onSaved,
          validator: validator,
          inputFormatters: inputFormatters,
          autovalidateMode: autovalidateMode,
          padding:
              decoration.contentPadding ??
              const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
          prefix:
              decoration.prefix ??
              decoration.prefixIcon ??
              _decorationText(decoration.prefixText, decoration.prefixStyle),
          suffix:
              decoration.suffix ??
              decoration.suffixIcon ??
              _decorationText(decoration.suffixText, decoration.suffixStyle),
          cupertinoDecoration:
              cupertinoDecoration ??
              BoxDecoration(
                color: backgroundColor,
                border: Border.all(
                  color: errorText == null ? colors.border : colors.warning,
                  width: errorText == null ? 0.5 : 1,
                ),
                borderRadius: AppRadius.borderMd,
              ),
        ),
        if (errorText != null || decoration.helperText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText ?? decoration.helperText!,
            style: AppTypography.caption.copyWith(
              color: errorText == null ? colors.textSecondary : colors.warning,
            ),
          ),
        ],
      ],
    );
  }
}

Widget? _decorationText(String? text, TextStyle? style) =>
    text == null ? null : Text(text, style: style);
