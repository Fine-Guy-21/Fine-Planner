import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/api_status.dart';
import '../../services/gpt_service.dart';

part 'api_event.dart';
part 'api_state.dart';

class ApiBloc extends Bloc<ApiEvent, ApiState> {
  late GptService gptService;

  ApiBloc() : super(const ApiInitial()) {
    on<InitializeApiEvent>(_onInitializeApi);
    on<GenerateSummaryEvent>(_onGenerateSummary);
    on<GenerateMotivationEvent>(_onGenerateMotivation);
    on<CheckApiValidityEvent>(_onCheckApiValidity);
  }

  Future<void> _onInitializeApi(
    InitializeApiEvent event,
    Emitter<ApiState> emit,
  ) async {
    try {
      gptService = GptService(apiToken: event.apiToken);
      
      // Check if API is still valid
      if (!gptService.isApiValid()) {
        emit(ApiExpiredState(
          daysRemaining: gptService.daysRemaining(),
        ));
      } else {
        emit(ApiReadyState(
          daysRemaining: gptService.daysRemaining(),
        ));
      }
    } catch (e) {
      emit(ApiErrorState(message: e.toString()));
    }
  }

  Future<void> _onGenerateSummary(
    GenerateSummaryEvent event,
    Emitter<ApiState> emit,
  ) async {
    emit(const ApiLoadingState());
    
    try {
      final response = await gptService.generateSummary(event.tasksSummary);
      
      if (response.status == ApiStatus.expired) {
        emit(ApiExpiredState(
          daysRemaining: gptService.daysRemaining(),
          message: response.message,
        ));
      } else if (response.status == ApiStatus.success) {
        emit(SummaryGeneratedState(
          summary: response.data ?? '',
          daysRemaining: gptService.daysRemaining(),
        ));
      } else {
        emit(ApiErrorState(message: response.message ?? 'Unknown error'));
      }
    } catch (e) {
      emit(ApiErrorState(message: e.toString()));
    }
  }

  Future<void> _onGenerateMotivation(
    GenerateMotivationEvent event,
    Emitter<ApiState> emit,
  ) async {
    try {
      final response = await gptService.generateMotivation(event.tasksCompleted);
      
      if (response.status == ApiStatus.success) {
        emit(MotivationGeneratedState(motivation: response.data ?? ''));
      }
    } catch (e) {
      // Silently fail - show cached motivation or generic message
    }
  }

  Future<void> _onCheckApiValidity(
    CheckApiValidityEvent event,
    Emitter<ApiState> emit,
  ) async {
    if (gptService.isApiValid()) {
      emit(ApiReadyState(
        daysRemaining: gptService.daysRemaining(),
      ));
    } else {
      emit(ApiExpiredState(
        daysRemaining: 0,
        message: 'API token expired on December 25, 2025',
      ));
    }
  }
}
