import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/repositories/user_profile_repository.dart';

/// Parameters for [SaveDisplayName].
typedef SaveDisplayNameParams = ({String displayName});

/// Validates and persists the user's display name.
///
/// Owns the rules so no UI widget has to: the form renders a field, this decides
/// whether what it holds is acceptable, and the failure carries a field-keyed
/// message the form can surface (`docs/Architecture.md` §8).
class SaveDisplayName implements UseCase<UserProfile, SaveDisplayNameParams> {
  const SaveDisplayName(this._repository);

  /// The longest name accepted, in characters.
  ///
  /// Counted in UTF-16 code units, which is what `String.length` gives. That
  /// over-counts an emoji slightly, and over-counting is the safe direction for
  /// a limit — Myanmar text renders in grapheme clusters that are several code
  /// units each, so a stricter limit is also the correct one here.
  static const int maxLength = 40;

  final UserProfileRepository _repository;

  @override
  Future<Result<UserProfile>> call(SaveDisplayNameParams params) async {
    // Trimmed, not rejected: a trailing space from a mobile keyboard is not a
    // mistake worth showing an error for.
    final name = params.displayName.trim();

    if (name.length > maxLength) {
      return const Err<UserProfile>(
        ValidationFailure(
          'Display name is too long',
          fieldErrors: <String, String>{'displayName': 'profileNameTooLong'},
          cause: null,
        ),
      );
    }

    // Newlines and other control characters would break the layout of any
    // surface that renders the name in one line, so they are rejected rather
    // than silently stripped — the user should know the name was not saved.
    if (_containsControlCharacter(name)) {
      return const Err<UserProfile>(
        ValidationFailure(
          'Display name contains control characters',
          fieldErrors: <String, String>{'displayName': 'profileNameInvalid'},
          cause: null,
        ),
      );
    }

    // The write is checked explicitly rather than via `flatMap`, which is
    // synchronous and cannot await the re-read. Returning the stored write's
    // failure (not the read's) keeps the reported reason about the save.
    final written = await _repository.saveDisplayName(name);
    if (written case Err<void>(:final failure)) {
      return Err<UserProfile>(failure);
    }

    return _repository.load();
  }

  /// True when [value] holds a C0/C1 control character or a line separator.
  static bool _containsControlCharacter(String value) {
    for (final rune in value.runes) {
      // C0 controls (includes \n, \t, \r) and DEL.
      if (rune < 0x20 || rune == 0x7F) return true;
      // C1 controls, which some IMEs emit for formatting.
      if (rune >= 0x80 && rune <= 0x9F) return true;
      // Unicode line/paragraph separators.
      if (rune == 0x2028 || rune == 0x2029) return true;
    }
    return false;
  }
}
