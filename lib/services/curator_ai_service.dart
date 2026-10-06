import '../services/locale_service.dart';
import 'curator_dialogue_engine.dart';

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

class CuratorAiService {
  static final CuratorAiService _instance = CuratorAiService._internal();
  factory CuratorAiService() => _instance;
  CuratorAiService._internal();

  final CuratorDialogueEngine _engine = CuratorDialogueEngine();

  /// Главная точка входа для общения с Персональным помощником.
  /// Архитектура: Local KB (мгновенно) → Vercel Gateway (GigaChat) fallback
  Future<CuratorResponse> ask(
    String userQuestion, {
    List<Map<String, String>> history = const [],
    required String lang,
    required String country,
  }) async {
    final locale = LocaleService();
    final ctx = CuratorContext.fromLocale(locale);
    
    return _engine.ask(userQuestion, ctx);
  }

  /// Версия с явным контекстом (используется в CuratorTab для freshLead)
  Future<CuratorResponse> askWithContext(
    String userQuestion, {
    List<Map<String, String>> history = const [],
    required CuratorContext ctx,
  }) async {
    return _engine.ask(userQuestion, ctx);
  }
}
