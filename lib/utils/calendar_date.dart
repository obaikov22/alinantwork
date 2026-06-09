DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime addCalendarDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

int calendarDayDifference(DateTime start, DateTime end) {
  final startDate = dateOnly(start);
  final endDate = dateOnly(end);
  var days = 0;
  var step = startDate;

  if (startDate.isAfter(endDate)) {
    while (step.isAfter(endDate)) {
      step = addCalendarDays(step, -1);
      days--;
    }
    return days;
  }

  while (step.isBefore(endDate)) {
    step = addCalendarDays(step, 1);
    days++;
  }
  return days;
}
