import 'package:flutter/material.dart';

/// Global key used to show SnackBars from outside the widget tree
/// (e.g., from background operations like saving a PDF receipt).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
