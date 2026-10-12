import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/usecases/load_user_profile.dart';
import 'package:ledgerly/features/profile/domain/usecases/save_avatar.dart';
import 'package:ledgerly/features/profile/domain/usecases/save_display_name.dart';
import 'package:ledgerly/features/profile/domain/usecases/watch_user_profile.dart';

import 'fake_user_profile_repository.dart';

/// The profile use cases.
///
/// The validation rules are the substance here — the pages have no validation of
/// their own, so anything these fail to reject reaches the settings table and is
/// then rendered by surfaces that assume it fits.
void main() {
  late FakeUserProfileRepository repository;

  setUp(() => repository = FakeUserProfileRepository());

  group('LoadUserProfile', () {
    test('should_return_the_stored_profile', () async {
      final result = await LoadUserProfile(repository).call(const NoParams());

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.displayName, '');
    });

    test('should_propagate_a_storage_failure', () async {
      repository.failure = const StorageFailure('disk gone', cause: null);

      final result = await LoadUserProfile(repository).call(const NoParams());

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('WatchUserProfile', () {
    test('should_emit_the_current_value_first', () async {
      final stream = WatchUserProfile(repository).call(const NoParams());
      final first = await stream.first;

      expect(first.isSuccess, isTrue);
    });

    test('should_emit_again_after_a_save', () async {
      final emissions = <String>[];
      final sub = WatchUserProfile(repository)
          .call(const NoParams())
          .listen(
            (result) => emissions.add(result.valueOrNull?.displayName ?? ''),
          );
      addTearDown(() async {
        await sub.cancel();
        await repository.dispose();
      });

      await SaveDisplayName(repository).call((displayName: 'Yin'));
      await Future<void>.delayed(Duration.zero);

      expect(emissions, contains('Yin'));
    });
  });

  group('SaveAvatar', () {
    test('should_persist_a_valid_avatar', () async {
      final avatar = AvatarConfig.initial.withPart(AvatarPart.shape, 2);

      final result = await SaveAvatar(repository).call((avatar: avatar));

      expect(result.isSuccess, isTrue);
      expect(repository.lastSavedAvatar, avatar);
      expect(result.valueOrNull?.avatar, avatar);
    });

    test('should_return_the_whole_profile_not_just_the_avatar', () async {
      repository = FakeUserProfileRepository(
        initial: const UserProfileFixture(name: 'Yin').profile,
      );

      final result = await SaveAvatar(repository)
          .call((avatar: AvatarConfig.initial.withPart(AvatarPart.eyes, 1)));

      // A caller that received only the avatar would keep its own copy of the
      // name, which is the second source of truth this guards against.
      expect(result.valueOrNull?.displayName, 'Yin');
    });

    test('should_reject_an_avatar_with_an_out_of_range_part', () async {
      final broken = AvatarConfig(
        backgroundColorIndex: AvatarCatalog.backgroundColors.length,
        backdropIndex: 0,
        shapeIndex: 0,
        eyesIndex: 0,
        mouthIndex: 0,
      );

      final result = await SaveAvatar(repository).call((avatar: broken));

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('should_not_write_when_the_avatar_is_rejected', () async {
      final broken = AvatarConfig(
        backgroundColorIndex: 0,
        backdropIndex: 0,
        shapeIndex: AvatarCatalog.shapes.length,
        eyesIndex: 0,
        mouthIndex: 0,
      );

      await SaveAvatar(repository).call((avatar: broken));

      expect(repository.saveAvatarCount, 0);
    });

    test('should_report_the_write_failure_rather_than_the_read', () async {
      repository.failure = const StorageFailure('locked', cause: null);

      final result = await SaveAvatar(repository)
          .call((avatar: AvatarConfig.initial));

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('SaveDisplayName', () {
    test('should_persist_a_plain_name', () async {
      final result = await SaveDisplayName(repository)
          .call((displayName: 'Yin Myat'));

      expect(result.isSuccess, isTrue);
      expect(repository.lastSavedName, 'Yin Myat');
      expect(result.valueOrNull?.displayName, 'Yin Myat');
    });

    test('should_trim_surrounding_whitespace', () async {
      await SaveDisplayName(repository).call((displayName: '  Yin  '));

      expect(repository.lastSavedName, 'Yin');
    });

    test('should_accept_an_empty_name', () async {
      // Clearing the name is a legitimate action: it returns the profile to its
      // guest state, and the page renders the placeholder for it.
      final result = await SaveDisplayName(repository).call((displayName: ''));

      expect(result.isSuccess, isTrue);
    });

    test('should_accept_a_name_exactly_at_the_limit', () async {
      final name = 'a' * SaveDisplayName.maxLength;

      final result = await SaveDisplayName(repository)
          .call((displayName: name));

      expect(result.isSuccess, isTrue);
    });

    test('should_reject_a_name_past_the_limit', () async {
      final name = 'a' * (SaveDisplayName.maxLength + 1);

      final result = await SaveDisplayName(repository)
          .call((displayName: name));

      expect(result.failureOrNull, isA<ValidationFailure>());
      final failure = result.failureOrNull! as ValidationFailure;
      expect(failure.fieldErrors['displayName'], 'profileNameTooLong');
    });

    test('should_not_write_when_the_name_is_too_long', () async {
      await SaveDisplayName(repository)
          .call((displayName: 'a' * (SaveDisplayName.maxLength + 1)));

      expect(repository.saveDisplayNameCount, 0);
    });

    test('should_reject_a_name_containing_a_newline', () async {
      final result = await SaveDisplayName(repository)
          .call((displayName: 'Yin\nMyat'));

      final failure = result.failureOrNull! as ValidationFailure;
      expect(failure.fieldErrors['displayName'], 'profileNameInvalid');
    });

    test('should_reject_a_name_containing_a_tab', () async {
      final result = await SaveDisplayName(repository)
          .call((displayName: 'Yin\tMyat'));

      expect(result.isErr, isTrue);
    });

    test('should_reject_a_name_containing_a_line_separator', () async {
      final result = await SaveDisplayName(repository)
          .call((displayName: 'Yin\u2028Myat'));

      expect(result.isErr, isTrue);
    });

    test('should_accept_myanmar_text', () async {
      // The renderer draws this in one line; nothing about the script should
      // trip the control-character check.
      const name = 'ရင်မောင်';

      final result = await SaveDisplayName(repository)
          .call((displayName: name));

      expect(result.isSuccess, isTrue);
      expect(repository.lastSavedName, name);
    });

    test('should_accept_an_emoji', () async {
      const name = 'Yin 🎉';

      final result = await SaveDisplayName(repository)
          .call((displayName: name));

      expect(result.isSuccess, isTrue);
    });

    test('should_reject_only_the_control_character_not_the_whole_script', () {
      // Guards against a future "sanitise" refactor that strips instead of
      // rejecting: a stripped name would save silently and differ from what the
      // user typed.
      const name = 'Yin\u0000';
      expect(name.contains('\u0000'), isTrue);
    });
  });
}

/// A tiny named wrapper so the one test that needs a non-default starting
/// profile reads clearly without a 6-field inline constructor.
class UserProfileFixture {
  const UserProfileFixture({required this.name});

  final String name;

  UserProfile get profile =>
      UserProfile(displayName: name, avatar: AvatarConfig.initial);
}
