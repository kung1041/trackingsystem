import 'package:http/http.dart' as http;
import 'voice_model.dart';

class VoiceModelService {
  //
  static const String url =
      'http://192.168.1.3:8080/ProjectFlutter/alldatavoice.php';

  static Future<List<VoiceModel>> getVoices() async {
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<VoiceModel> voices = voiceFromJson(response.body);
        return voices;
      } else {
        return List<VoiceModel>();
      }
    } catch (e) {
      return List<VoiceModel>();
    }
  }
}
