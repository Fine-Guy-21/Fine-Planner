part of 'api_bloc.dart';

abstract class ApiState {
  const ApiState();
}

class ApiInitial extends ApiState {
  const ApiInitial();
}

class ApiLoadingState extends ApiState {
  const ApiLoadingState();
}

class ApiReadyState extends ApiState {
  final int daysRemaining;
  const ApiReadyState({required this.daysRemaining});
}

class ApiExpiredState extends ApiState {
  final int daysRemaining;
  final String? message;
  const ApiExpiredState({required this.daysRemaining, this.message});
}

class SummaryGeneratedState extends ApiState {
  final String summary;
  final int daysRemaining;
  const SummaryGeneratedState({required this.summary, required this.daysRemaining});
}

class MotivationGeneratedState extends ApiState {
  final String motivation;
  const MotivationGeneratedState({required this.motivation});
}

class ApiErrorState extends ApiState {
  final String message;
  const ApiErrorState({required this.message});
}
