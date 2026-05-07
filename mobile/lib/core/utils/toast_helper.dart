// toast_helper.dart — FLIGHTLY Toast Notification Helpers
// Centralized toast functions so every screen uses the same style consistently.
// WHY: Having helpers prevents inconsistent toast styles spread across the app —
//      one change here updates toasts everywhere.

import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

/// Show a green success toast at the top of the screen.
void showSuccessToast(BuildContext context, String message) {
  showTopSnackBar(
    Overlay.of(context),
    CustomSnackBar.success(message: message),
  );
}

/// Show a red error toast at the top of the screen.
void showErrorToast(BuildContext context, String message) {
  showTopSnackBar(
    Overlay.of(context),
    CustomSnackBar.error(message: message),
  );
}

/// Show a blue info toast at the top of the screen.
void showInfoToast(BuildContext context, String message) {
  showTopSnackBar(
    Overlay.of(context),
    CustomSnackBar.info(message: message),
  );
}
