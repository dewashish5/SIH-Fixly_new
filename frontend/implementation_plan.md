# Implementation Plan: Replace SnackBar with Toastification

## Objective
Replace all `ScaffoldMessenger.of(context).showSnackBar` usages with `toastification` package. Toasts should appear at the top with a fade-in / ease-out animation and apply to the entire app.

## Steps
1. **Wrap App with ToastificationWrapper**: Modify `lib/main.dart` or `lib/core/app.dart` to include `ToastificationWrapper`.
2. **Create Toast Utils**: Create `lib/core/utils/toast_utils.dart` with a `ToastUtils.showToast` method configuring global styling (top alignment, fade-in/ease-out).
3. **Replace SnackBars**: Iterate over occurrences of `showSnackBar` and replace them with `ToastUtils.showToast()`.

## Verification
- Test compile to ensure no syntax errors.
