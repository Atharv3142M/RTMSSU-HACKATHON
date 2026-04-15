import 'package:get/get.dart';
import '../../services/google_generative_ai_api_service.dart';

class ChatBotController extends GetxController {
  final GoogleGenerativeAiApiService _apiService = GoogleGenerativeAiApiService();

  // List of messages, each message is a map with sender ('user' or 'bot') and text
  RxList<Map<String, String>> messages = <Map<String, String>>[].obs;
  RxBool isLoading = false.obs;

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;
    messages.add({'sender': 'user', 'text': userMessage});
    isLoading.value = true;
    try {
      final botResponse = await _apiService.getResponseForGivenPrompt(userMessage);
      messages.add({'sender': 'bot', 'text': botResponse});
    } catch (e) {
      messages.add({'sender': 'bot', 'text': 'Failed to get response.'});
    } finally {
      isLoading.value = false;
    }
  }

  void clearMessages() {
    messages.clear();
  }
}
