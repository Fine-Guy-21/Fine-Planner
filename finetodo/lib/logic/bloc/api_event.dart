part of 'api_bloc.dart';

abstract class ApiEvent {}

class InitializeApiEvent extends ApiEvent {
  final String apiToken;
  InitializeApiEvent(this.apiToken);
}

class GenerateSummaryEvent extends ApiEvent {
  final String tasksSummary;
  GenerateSummaryEvent(this.tasksSummary);
}

class GenerateMotivationEvent extends ApiEvent {
  final int tasksCompleted;
  GenerateMotivationEvent(this.tasksCompleted);
}

class CheckApiValidityEvent extends ApiEvent {}
