import 'package:dlna_player/model/content_class.dart';

class RawContent {
  String id;
  String parentId;
  ContentClass classType;
  String artist;
  String title;
  String album;
  String genre;
  DateTime? date;
  int numTracks;
  int trackNum;
  String duration;
  String? albumArt;
  String? trackUrl;

  RawContent({
    this.id = '',
    this.parentId = '',
    this.classType = ContentClass.none,
    this.artist = '',
    this.title = '',
    this.album = '',
    this.genre = '',
    this.date,
    this.numTracks = 0,
    this.trackNum = 0,
    this.duration = '',
    this.albumArt,
    this.trackUrl,
  });
}
