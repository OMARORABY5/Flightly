// account_provider.dart — FLIGHTLY Account Providers
// Handles Profile and Settings state

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/features/account/domain/models/profile.dart';
import 'package:flightly/features/account/domain/models/settings.dart';
import 'package:flightly/features/account/domain/repositories/account_repository.dart';
import 'package:flightly/features/account/data/repositories/account_repository_impl.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(dioClient: DioClient.instance());
});

// ─── Profile Provider ─────────────────────────────────────────────────────────
final profileProvider = FutureProvider<Profile?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return null;
  return ref.read(accountRepositoryProvider).getProfile();
});

// ─── Settings Provider ────────────────────────────────────────────────────────
final settingsProvider = FutureProvider<Settings?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return null;
  return ref.read(accountRepositoryProvider).getSettings();
});
