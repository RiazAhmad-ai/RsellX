/// Date and time utility functions for the application
class DateTimeUtils {
  // Prevent instantiation
  DateTimeUtils._();

  /// Check if two dates are the same day (ignoring time)
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Get formatted date string  (DD/MM/YYYY)
  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  /// Get short date string (DD/MM)
  static String formatShortDate(DateTime date) {
    return "${date.day}/${date.month}";
  }

  /// Get formatted time string (12-hour with AM/PM)
  static String formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  /// Get formatted date and time string
  static String formatDateTime(DateTime dateTime) {
    return "${formatDate(dateTime)} at ${formatTime(dateTime)}";
  }

  /// Get formatted log string (for payment logs, edit logs, etc.)
  /// Format: "Action on DD/MM at HH:MM AM/PM"
  static String formatLogEntry(String action, DateTime dateTime) {
    return "$action on ${formatShortDate(dateTime)} at ${formatTime(dateTime)}";
  }

  /// Get relative time string (e.g., "Today", "Yesterday", or date)
  static String getRelativeDate(DateTime date) {
    if (isToday(date)) return "Today";
    if (isYesterday(date)) return "Yesterday";
    return formatDate(date);
  }

  /// Get start of day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return startOfDay(monday);
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final sunday = date.add(Duration(days: 7 - date.weekday));
    return endOfDay(sunday);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = date.month == 12
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  /// Check if date is in range (inclusive)
  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end.add(const Duration(seconds: 1)));
  }

  /// Get days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = startOfDay(from);
    to = startOfDay(to);
    return to.difference(from).inDays;
  }

  /// Check if date is overdue
  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return dueDate.isBefore(DateTime.now());
  }

  /// Get days until due
  static int daysUntilDue(DateTime? dueDate) {
    if (dueDate == null) return 0;
    return daysBetween(DateTime.now(), dueDate);
  }

  /// Format duration in readable format
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return "${duration.inDays} day${duration.inDays > 1 ? 's' : ''}";
    } else if (duration.inHours > 0) {
      return "${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}";
    } else {
      return "Just now";
    }
  }

  /// Get time ago string (e.g., "2 hours ago")
  static String timeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 30) {
      final months = duration.inDays ~/ 30;
      return "$months month${months > 1 ? 's' : ''} ago";
    } else if (duration.inDays > 0) {
      return "${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago";
    } else if (duration.inHours > 0) {
      return "${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }
}
