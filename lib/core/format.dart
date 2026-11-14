/// Small helpers to show dates the way the Figma does ("5-9 Oct", "4 days").
class Fmt {
  Fmt._();

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// "2026-10-05" -> DateTime at midnight (or null)
  static DateTime? parseDay(String s) {
    final d = DateTime.tryParse(s);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// DateTime -> "2026-10-05" (the format the backend wants)
  static String toApi(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// "5 Oct 2026"
  static String dayLong(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  static String day(String s) {
    final d = parseDay(s);
    return d == null ? s : dayLong(d);
  }

  /// "Fri, 9 Oct"
  static String dayWithWeekday(String s) {
    final d = parseDay(s);
    if (d == null) return s;
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';
  }

  /// "5-9 Oct"  or  "28 Oct - 2 Nov"
  static String range(String start, String end) {
    final a = parseDay(start);
    final b = parseDay(end);
    if (a == null || b == null) return '$start - $end';
    if (a.month == b.month && a.year == b.year) {
      return '${a.day}\u2013${b.day} ${_months[a.month - 1]}';
    }
    return '${a.day} ${_months[a.month - 1]} \u2013 ${b.day} ${_months[b.month - 1]}';
  }

  static int totalDays(String start, String end) {
    final a = parseDay(start);
    final b = parseDay(end);
    if (a == null || b == null) return 0;
    return b.difference(a).inDays + 1;
  }

  /// "4 days" / "1 day"
  static String daysText(int n) => n == 1 ? '1 day' : '$n days';

  /// Days from today until [end] (negative = already passed)
  static int daysLeft(String end) {
    final e = parseDay(end);
    if (e == null) return 0;
    return e.difference(today()).inDays;
  }

  /// "5 min ago", "1h ago", "3d ago"
  static String ago(DateTime? t) {
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Loan reference like the Figma ("BC1048")
  static String loanCode(int id) => 'BC${1000 + id}';
}
