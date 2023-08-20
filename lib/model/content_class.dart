enum ContentClass {
  none(''),
  album('object.container.album.musicAlbum'),
  albums('object.container.album'),
  genre('object.container.genre.musicGenre'),
  artist('object.container.person.musicArtist'),
  artists('object.container.person'),
  track('object.item.audioItem.musicTrack'),
  folder('object.container.storageFolder'),
  playlist('object.container.playlistContainer');

  final String className;

  const ContentClass(this.className);
}

extension ContentClassExt on String {
  ContentClass toContentClass() => ContentClass.values.firstWhere(
        (type) => type.className == this,
        orElse: () => ContentClass.none,
      );
}
