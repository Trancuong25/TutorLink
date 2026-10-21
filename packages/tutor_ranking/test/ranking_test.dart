import 'package:test/test.dart';
import 'package:tutor_ranking/tutor_ranking.dart';

RankingWeights weights() => RankingWeights({
  'subject': .30,
  'schedule': .25,
  'distance': .20,
  'price': .15,
  'rating': .10,
});
TutorCandidate candidate({
  String uid = 't',
  double lon = 0,
  Set<int> slots = const {0, 1},
  Set<String> levels = const {'high'},
  Set<String> subjects = const {'math'},
  double price = 100,
  double average = 4,
  int count = 10,
  bool available = true,
}) => TutorCandidate(
  uid: uid,
  subjects: subjects,
  levels: levels,
  slots: slots,
  position: Position(0, lon),
  hourlyRate: price,
  ratingAvg: average,
  ratingCount: count,
  isAvailable: available,
);
const request = RankingRequest(
  subject: 'math',
  level: 'high',
  center: Position(0, 0),
  radiusKm: 10,
  budget: 100,
  slots: {0, 1},
);
void main() {
  test('Jaccard giao/hợp, rỗng và biên', () {
    expect(jaccard({0, 1}, {0, 1}), 1);
    expect(jaccard({0}, {1}), 0);
    expect(jaccard({0, 1}, {1, 2}), closeTo(1 / 3, 1e-10));
    expect(jaccard({}, {}), 0);
  });
  test('giá đủ ngân sách, tuyến tính, giá gấp đôi và cao hơn', () {
    expect(priceScore(50, 100), 1);
    expect(priceScore(100, 100), 1);
    expect(priceScore(150, 100), .5);
    expect(priceScore(200, 100), 0);
    expect(priceScore(300, 100), 0);
    expect(() => priceScore(100, 0), throwsArgumentError);
  });
  test('Bayesian 0/ít/nhiều lượt và biên 0/1', () {
    expect(bayesianRating(0, 0, 4), .8);
    expect(bayesianRating(5, 1, 3), closeTo(20 / 30, 1e-10));
    expect(bayesianRating(5, 10000, 3), greaterThan(.999));
    expect(bayesianRating(0, 10, 0), 0);
    expect(bayesianRating(5, 10, 5), 1);
  });
  test('điểm môn, lịch, khoảng cách và tổng đúng công thức', () {
    final a = rankTutors([candidate()], request, weights(), 4).single;
    expect(a.components['subject'], 1);
    expect(a.components['schedule'], 1);
    expect(a.components['distance'], 1);
    expect(a.score, closeTo(.98, 1e-10));
    final b = rankTutors(
      [
        candidate(levels: {'primary'}, slots: {5}),
      ],
      request,
      weights(),
      4,
    ).single;
    expect(b.components['subject'], .5);
    expect(b.components['schedule'], 0);
    final edgeLon = 10 / 6371 * 180 / 3.141592653589793;
    final edge = rankTutors(
      [candidate(lon: edgeLon)],
      const RankingRequest(
        subject: 'math',
        center: Position(0, 0),
        radiusKm: 10.00000001,
      ),
      weights(),
      4,
    ).single;
    expect(edge.components['distance'], closeTo(0, 1e-8));
  });
  test('bỏ schedule/price rồi chuẩn hóa, không phạt thiếu dữ liệu', () {
    for (final req in [
      const RankingRequest(
        subject: 'math',
        center: Position(0, 0),
        radiusKm: 10,
      ),
      const RankingRequest(
        subject: 'math',
        center: Position(0, 0),
        radiusKm: 10,
        budget: 100,
      ),
      const RankingRequest(
        subject: 'math',
        center: Position(0, 0),
        radiusKm: 10,
        slots: {0},
      ),
    ]) {
      final r = rankTutors([candidate()], req, weights(), 4).single;
      expect(
        r.effectiveWeights.values.reduce((a, b) => a + b),
        closeTo(1, 1e-10),
      );
      expect(r.effectiveWeights.containsKey('schedule'), req.slots.isNotEmpty);
      expect(r.effectiveWeights.containsKey('price'), req.budget != null);
    }
    final r = rankTutors(
      [candidate()],
      const RankingRequest(
        subject: 'math',
        center: Position(0, 0),
        radiusKm: 10,
      ),
      weights(),
      4,
    ).single;
    expect(r.components['schedule'], null);
    expect(r.components['price'], null);
    expect(r.effectiveWeights['subject'], closeTo(.5, 1e-10));
  });
  test('lọc cứng môn, sẵn sàng, bán kính ở cả hai chế độ', () {
    final list = [
      candidate(uid: 'valid'),
      candidate(uid: 'subject', subjects: {'english'}),
      candidate(uid: 'off', available: false),
      candidate(uid: 'far', lon: 1),
    ];
    for (final mode in RankingMode.values) {
      expect(
        rankTutors(
          list,
          request,
          weights(),
          4,
          mode: mode,
        ).map((r) => r.tutor.uid),
        ['valid'],
      );
    }
  });
  test('hai chế độ đổi thứ tự trên cùng tập ứng viên', () {
    final list = [
      candidate(
        uid: 'near',
        lon: .001,
        price: 300,
        slots: {5},
        levels: {'primary'},
      ),
      candidate(uid: 'fit', lon: .01),
    ];
    expect(
      rankTutors(
        list,
        request,
        weights(),
        4,
        mode: RankingMode.nearest,
      ).first.tutor.uid,
      'near',
    );
    expect(rankTutors(list, request, weights(), 4).first.tutor.uid, 'fit');
  });
  test('tie-break khoảng cách rồi uid ổn định, không sửa input', () {
    final w = RankingWeights({
      'subject': 1,
      'schedule': 0,
      'distance': 0,
      'price': 0,
      'rating': 0,
    });
    final list = [
      candidate(uid: 'z', lon: .01),
      candidate(uid: 'b'),
      candidate(uid: 'a'),
    ];
    expect(rankTutors(list, request, w, 4).map((r) => r.tutor.uid), [
      'a',
      'b',
      'z',
    ]);
    expect(list.first.uid, 'z');
  });
  test('trọng số sai hoặc toàn trọng số bị bỏ được từ chối rõ', () {
    for (final v in [-1.0, double.nan, double.infinity, .7]) {
      expect(
        () => RankingWeights({...weights().values, 'subject': v}),
        throwsArgumentError,
      );
    }
    expect(() => RankingWeights({'subject': 1}), throwsArgumentError);
    final w = RankingWeights({
      'subject': 0,
      'schedule': 1,
      'distance': 0,
      'price': 0,
      'rating': 0,
    });
    expect(
      () => w.effective(
        const RankingRequest(
          subject: 'math',
          center: Position(0, 0),
          radiusKm: 10,
        ),
      ),
      throwsArgumentError,
    );
  });
  test(
    'lý do dùng giao lịch thật, làm tròn khoảng cách và không lộ tọa độ',
    () {
      final r = rankTutors(
        [
          candidate(slots: {0, 1, 2}, lon: .01),
        ],
        request,
        weights(),
        4,
      ).single;
      expect(r.reasons, contains('Trùng 2/2 buổi bạn cần'));
      expect(r.reasons.any((s) => s.contains('(gần đúng)')), true);
      expect(r.components['schedule'], closeTo(2 / 3, 1e-10));
    },
  );
}
