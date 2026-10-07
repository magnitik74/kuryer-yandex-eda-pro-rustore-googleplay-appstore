import 'curator_dialogue_engine.dart';
import 'locale_service.dart';

export 'curator_dialogue_engine.dart';

class CuratorMessage {
  final String text;
  final bool isUser;
  final bool isActionCard;
  final String? actionType;
  final DateTime timestamp;

  CuratorMessage({
    required this.text,
    required this.isUser,
    this.isActionCard = false,
    this.actionType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Сервис-фасад для куратора, делегирующий запросы в CuratorDialogueEngine
class CuratorAiService {
  static final CuratorAiService _instance = CuratorAiService._internal();
  factory CuratorAiService() => _instance;
  CuratorAiService._internal();

  final CuratorDialogueEngine _engine = CuratorDialogueEngine();

  Future<CuratorResponse> ask(
    String userQuestion, {
    List<Map<String, String>> history = const [],
    required String lang,
    required String country,
  }) async {
    final ctx = CuratorContext.fromLocale(LocaleService());
    return await _engine.processQuery(userQuestion, ctx);
  }
}
