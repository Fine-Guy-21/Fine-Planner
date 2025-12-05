part of 'task_form_bloc.dart';

abstract class TaskFormState {
  final String? title;
  final String? description;
  final String? categoryId;
  final DateTime? dueDate;
  final bool isRecurring;
  final String? recurrencePattern;

  const TaskFormState({
    this.title,
    this.description,
    this.categoryId,
    this.dueDate,
    this.isRecurring = false,
    this.recurrencePattern,
  });
}

// for accepting a new user input which (add task)
class TaskFormReadyState extends TaskFormState {
  const TaskFormReadyState({
    super.title,
    super.description,
    super.categoryId,
    super.dueDate,
    super.isRecurring = false,
    super.recurrencePattern,
  });
}

// for initializing a pre-existing task (edit task)
class TaskFormLoadingState extends TaskFormState {
  final TaskModel initialTask;

  const TaskFormLoadingState({
    required this.initialTask,
    super.title,
    super.description,
    super.categoryId,
    super.dueDate,
    super.isRecurring,
    super.recurrencePattern,
  });
}

/// State indicating that form data is being processed/saved.
class TaskFormSubmittingState extends TaskFormState {
  const TaskFormSubmittingState({
    super.title,
    super.description,
    super.categoryId,
    super.dueDate,
    super.isRecurring,
    super.recurrencePattern,
  });
}

/// State for successful form submission.
class TaskFormSuccessState extends TaskFormState {
  final String successMessage;
  const TaskFormSuccessState({required this.successMessage});
}

/// State for failed form submission or failed loading of initial data.
class TaskFormFailureState extends TaskFormState {
  final String errorMessage;
  const TaskFormFailureState({required this.errorMessage});
}
