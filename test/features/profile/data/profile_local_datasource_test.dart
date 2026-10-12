import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/features/profile/data/datasources/profile_keys.dart';
import 'package:ledgerly/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';

import '../../../core/database/db_harness.dart';

/// The profile datasource: the encode/decode boundary.
///
/// The cases that matter are the *unhappy* ones. The profile is read during app
/// startup, before any screen exists to show an error, so a missing key, an empty
/// string or a value from a future build must all degrade to the default instead
/// of throwing.
///
/// These tests need a real SQLite database, so they run on the device/CI harness
/// rather than in the in-process test runner (`docs/Agent.md` §6).
void main() {
  ProfileLocalDataSource make() {
    final harness = useDbHarness();
    return ProfileLocalDataSource(
      AppSettingsDao(harness.db, clock: harness.clock),
    );
  }

  group('read on a fresh install', () {
    test('should_return_the_initial_profile', () async {
      final datasource = make();

      expect(await datasource.read(), UserProfile.initial);
    });
  });

  group('write and read round-trip', () {
    test('should_persist_the_name_and_the_avatar', () async {
      final datasource = make();
      final profile = UserProfile(
        displayName: 'Yin',
        avatar: AvatarConfig.initial.withPart(AvatarPart.shape, 2),
      );

      await datasource.write(profile);

      expect(await datasource.read(), profile);
    });

    test('should_store_the_avatar_in_its_encoded_form', () async {
      final harness = useDbHarness();
      final dao = AppSettingsDao(harness.db, clock: harness.clock);
      final datasource = ProfileLocalDataSource(dao);

      await datasource.write(
        UserProfile(
          displayName: 'Yin',
          avatar: AvatarConfig.initial.withPart(AvatarPart.eyes, 3),
        ),
      );

      // Read the table itself: the point is what is physically stored, and a
      // future refactor to JSON would need to be a deliberate decision.
      final raw = await dao.read(ProfileKeys.avatar);
      expect(AvatarConfig.tryParse(raw ?? ''), isNotNull);
    });

    test('should_write_only_the_avatar_and_leave_the_name_alone', () async {
      final datasource = make();
      await datasource.writeDisplayName('Yin');

      await datasource.writeAvatar(
        AvatarConfig.initial.withPart(AvatarPart.mouth, 1),
      );

      final profile = await datasource.read();
      expect(profile.displayName, 'Yin');
      expect(profile.avatar.mouthIndex, 1);
    });

    test('should_write_only_the_name_and_leave_the_avatar_alone', () async {
      final datasource = make();
      await datasource.writeAvatar(
        AvatarConfig.initial.withPart(AvatarPart.shape, 1),
      );

      await datasource.writeDisplayName('Yin');

      final profile = await datasource.read();
      expect(profile.displayName, 'Yin');
      expect(profile.avatar.shapeIndex, 1);
    });
  });

  group('decode fallbacks', () {
    test('should_treat_a_missing_avatar_key_as_the_initial_avatar', () async {
      final harness = useDbHarness();
      final dao = AppSettingsDao(harness.db, clock: harness.clock);
      final datasource = ProfileLocalDataSource(dao);

      await dao.put(key: ProfileKeys.displayName, value: 'Yin');

      final profile = await datasource.read();
      expect(profile.displayName, 'Yin');
      expect(profile.avatar, UserProfile.initial.avatar);
    });

    test('should_fall_back_when_the_avatar_is_malformed', () async {
      final harness = useDbHarness();
      final dao = AppSettingsDao(harness.db, clock: harness.clock);
      final datasource = ProfileLocalDataSource(dao);

      await dao.put(key: ProfileKeys.avatar, value: 'not-an-avatar');

      expect((await datasource.read()).avatar, UserProfile.initial.avatar);
    });

    test('should_fall_back_when_the_avatar_index_is_out_of_range', () async {
      final harness = useDbHarness();
      final dao = AppSettingsDao(harness.db, clock: harness.clock);
      final datasource = ProfileLocalDataSource(dao);

      // A value a future build with more options could legitimately write.
      final tooBig = AvatarConfig(
        backgroundColorIndex: AvatarCatalog.backgroundColors.length + 3,
        backdropIndex: 0,
        shapeIndex: 0,
        eyesIndex: 0,
        mouthIndex: 0,
      );
      await dao.put(key: ProfileKeys.avatar, value: tooBig.encode());

      expect((await datasource.read()).avatar, UserProfile.initial.avatar);
    });

    test('should_fall_back_when_the_avatar_is_an_empty_string', () async {
      final harness = useDbHarness();
      final dao = AppSettingsDao(harness.db, clock: harness.clock);
      final datasource = ProfileLocalDataSource(dao);

      await dao.put(key: ProfileKeys.avatar, value: '');

      expect((await datasource.read()).avatar, UserProfile.initial.avatar);
    });
  });

  group('watch', () {
    test('should_emit_the_current_profile_first', () async {
      final datasource = make();

      final first = await datasource.watch().first;

      expect(first, UserProfile.initial);
    });

    test('should_emit_again_after_a_name_write', () async {
      final datasource = make();
      final seen = <String>[];
      final sub = datasource.watch().listen(
        (profile) => seen.add(profile.displayName),
      );
      addTearDown(sub.cancel);

      await datasource.writeDisplayName('Yin');
      await Future<void>.delayed(Duration.zero);

      expect(seen, contains('Yin'));
    });

    test('should_emit_again_after_an_avatar_write', () async {
      final datasource = make();
      final seen = <AvatarConfig>[];
      final sub = datasource.watch().listen(
        (profile) => seen.add(profile.avatar),
      );
      addTearDown(sub.cancel);

      final avatar = AvatarConfig.initial.withPart(AvatarPart.shape, 3);
      await datasource.writeAvatar(avatar);
      await Future<void>.delayed(Duration.zero);

      expect(seen, contains(avatar));
    });
  });
}
