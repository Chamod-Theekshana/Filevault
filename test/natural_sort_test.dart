import 'package:filevault/domain/models/sort_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int cmp(String a, String b) => SortSpec.naturalCompare(a, b);

  test('numbers compare by value, not by characters', () {
    expect(cmp('file2', 'file10'), lessThan(0));
    expect(cmp('file10', 'file2'), greaterThan(0));
    expect(cmp('IMG_0009.jpg', 'IMG_0010.jpg'), lessThan(0));
  });

  test('comparison is case-insensitive', () {
    expect(cmp('Alpha', 'alpha'), 0);
    expect(cmp('beta', 'Alpha'), greaterThan(0));
  });

  test('shorter prefix sorts first', () {
    expect(cmp('report', 'report 2'), lessThan(0));
    expect(cmp('a', 'a'), 0);
  });

  test('leading zeros only break ties', () {
    expect(cmp('track 01', 'track 1'), greaterThan(0));
    expect(cmp('track 01', 'track 2'), lessThan(0));
  });

  test('sorting a large list stays correct', () {
    final List<String> names = List<String>.generate(500, (int i) => 'photo ${500 - i}.jpg');
    names.sort(cmp);
    expect(names.first, 'photo 1.jpg');
    expect(names[9], 'photo 10.jpg');
    expect(names.last, 'photo 500.jpg');
  });
}
