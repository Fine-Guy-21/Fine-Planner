part of 'task_form_bloc.dart';

/// Abstract base class for the Task Form's actions.
abstract class TaskFormEvent {
  const TaskFormEvent();
}

// event to load initial data for editing.
class LoadTaskForEditEvent extends TaskFormEvent {
  final String taskId;
  const LoadTaskForEditEvent({required this.taskId});
}

// Events for updating form fields
class UpdateFormTitleEvent extends TaskFormEvent {
  final String title;
  const UpdateFormTitleEvent(this.title);
}

class UpdateFormDescriptionEvent extends TaskFormEvent {
  final String description;
  const UpdateFormDescriptionEvent(this.description);
}

class UpdateFormCategoryEvent extends TaskFormEvent {
  final String categoryId;
  const UpdateFormCategoryEvent(this.categoryId);
}

class UpdateFormDueDateEvent extends TaskFormEvent {
  final DateTime? dueDate;
  const UpdateFormDueDateEvent(this.dueDate);
}

class UpdateFormRecurringEvent extends TaskFormEvent {
  final bool isRecurring;
  const UpdateFormRecurringEvent(this.isRecurring);
}

class UpdateFormRecurrencePatternEvent extends TaskFormEvent {
  final String? recurrencePattern;
  const UpdateFormRecurrencePatternEvent(this.recurrencePattern);
}

// event triggered when the user hits 'Update'
class UpdateTaskFormEvent extends TaskFormEvent {
  const UpdateTaskFormEvent();
}

// event triggered when the user click 'add' button
class AddTaskFormEvent extends TaskFormEvent {
  const AddTaskFormEvent();
}

// event to reset form
class ResetFormEvent extends TaskFormEvent {
  const ResetFormEvent();
}
