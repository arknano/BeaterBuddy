class WBTrack {
  final int id;
  final String title;
  final String pageURL;
  final String author;
  final String? authorURL;
  final int week;
  final int year;
  final String audioURL;
  final String imageURL;

  WBTrack({
    required this.id,
    required this.title,
    required this.pageURL,
    required this.author,
    this.authorURL,
    required this.week,
    required this.year,
    required this.audioURL,
    required this.imageURL,
  });
}
