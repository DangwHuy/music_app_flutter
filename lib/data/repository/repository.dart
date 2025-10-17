import 'package:lan2tesst/data/model/song.dart';
import 'package:lan2tesst/data/source/source.dart';

abstract interface class Repository {
  Future<List<Song>?> loadData();
}

class DefaultRepository implements Repository {
  final _localDataSource = LocalDataSource();
  final _remoteDataSource = RemoteDataSource();

  @override
  Future<List<Song>?> loadData() async {
    List<Song> songs = [];

    // Thử tải dữ liệu từ remote
    final remoteSongs = await _remoteDataSource.loadData();

    if (remoteSongs == null || remoteSongs.isEmpty) {
      // Nếu remote thất bại, thử local
      final localSongs = await _localDataSource.loadData();
      if (localSongs != null) {
        songs.addAll(localSongs);
      }
    } else {
      songs.addAll(remoteSongs);
    }

    return songs;
  }
}
