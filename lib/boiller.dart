int count30thsPassed(DateTime startDate, DateTime endDate) {
  if (startDate.isAfter(endDate)) {
    return 0; // Return 0 if the date range is invalid
  }

  int count = 0;
  DateTime current = DateTime(startDate.year, startDate.month, 28);
  if (current.month == 2) {
    current = DateTime(startDate.year, startDate.month, 28);
  } else {
    current = DateTime(startDate.year, startDate.month, 30);
  }
  while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
    if (current.month == 2) {
      current = DateTime(current.year, 2, 28);
      if (current.isAfter(startDate) &&
          (current.isBefore(endDate) || current.isAtSameMomentAs(endDate))) {
        count++;
      }
    } else {
      count++;
    }
    // Move to the next month's 30th (or closest valid date)
    if (current.month == 1) {
      current = DateTime(current.year, current.month + 1, 28);
    } else {
      current = DateTime(current.year, current.month + 1, 30);
    }
  }

  return count;
}

void main() {
  DateTime start = DateTime(2025, 1, 15);
  DateTime end = DateTime(2026, 3, 30);

  print("Number of 30ths passed: ${count30thsPassed(start, end)}");
}
