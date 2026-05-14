class ReadingStats {
  final int totalDocuments;
  final int completedDocuments;
  final int currentlyReading;
  final int totalPagesRead;
  final int streakDays;
  final Duration totalReadingTime;
  final Map<String, int> readingByDay; // day key -> minutes

  const ReadingStats({
    this.totalDocuments = 0,
    this.completedDocuments = 0,
    this.currentlyReading = 0,
    this.totalPagesRead = 0,
    this.streakDays = 0,
    this.totalReadingTime = Duration.zero,
    this.readingByDay = const {},
  });

  ReadingStats copyWith({
    int? totalDocuments,
    int? completedDocuments,
    int? currentlyReading,
    int? totalPagesRead,
    int? streakDays,
    Duration? totalReadingTime,
    Map<String, int>? readingByDay,
  }) {
    return ReadingStats(
      totalDocuments: totalDocuments ?? this.totalDocuments,
      completedDocuments: completedDocuments ?? this.completedDocuments,
      currentlyReading: currentlyReading ?? this.currentlyReading,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      streakDays: streakDays ?? this.streakDays,
      totalReadingTime: totalReadingTime ?? this.totalReadingTime,
      readingByDay: readingByDay ?? this.readingByDay,
    );
  }

  String get formattedReadingTime {
    final hours = totalReadingTime.inHours;
    final minutes = totalReadingTime.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
