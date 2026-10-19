import 'package:flutter_test/flutter_test.dart';
import 'package:tutorlink/features/tutor_profile/domain/tutor_profile.dart';

TutorProfile profile({
  int rate = 150000,
  List<String> subjects = const ['math'],
  List<String> levels = const ['high'],
  Set<int> slots = const {2, 5},
  String name = 'An',
}) => TutorProfile(
  uid: 't',
  displayName: name,
  bio: '',
  subjects: subjects,
  levels: levels,
  hourlyRate: rate,
  availability: slots,
);
void main() {
  test('validate giá biên, môn, cấp và 21 ô lịch', () {
    expect(profile(rate: 50000).validate(), isNull);
    expect(profile(rate: 1000000).validate(), isNull);
    for (final p in [
      profile(rate: 49999),
      profile(rate: 1000001),
      profile(subjects: []),
      profile(levels: []),
      profile(subjects: ['invalid']),
      profile(slots: {21}),
      profile(slots: {}),
      profile(name: ' '),
    ]) {
      expect(p.validate(), isNotNull);
    }
    expect(
      profile(slots: Set.from(List.generate(21, (i) => i))).validate(),
      isNull,
    );
  });
}
