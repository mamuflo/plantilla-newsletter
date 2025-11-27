import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class YouTubeService {
  final GoogleSignInAccount account;

  YouTubeService(this.account);

  Future<youtube.YouTubeApi> getYouTubeApi() async {
    final googleAuth = await account.authentication;
    final headers = {
      'Authorization': 'Bearer ${googleAuth.accessToken}',
    };
    final client = GoogleAuthClient(headers);
    return youtube.YouTubeApi(client);
  }

  Future<youtube.Video?> uploadVideo(PlatformFile file, String title, String description) async {
    try {
      final youtubeApi = await getYouTubeApi();

      final video = youtube.Video();
      video.snippet = youtube.VideoSnippet()
        ..title = title
        ..description = description;
      video.status = youtube.VideoStatus()..privacyStatus = 'private'; // or 'public' or 'unlisted'

      final media = youtube.Media(file.readStream!, file.size);

      return await youtubeApi.videos.insert(video, ['snippet', 'status'], uploadMedia: media);
    } catch (e) {
      // Consider logging the error
      // Return null or throw a more specific exception to be handled by the UI.
      return null;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
