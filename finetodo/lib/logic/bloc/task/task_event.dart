part of 'task_bloc.dart';

abstract class TaskEvent {}

class LoadTasksEvent extends TaskEvent {}

class AddTaskEvent extends TaskEvent {
  final TaskModel task;
  AddTaskEvent(this.task);
}

class UpdateTaskEvent extends TaskEvent {
  final TaskModel task;
  UpdateTaskEvent(this.task);
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;
  DeleteTaskEvent(this.taskId);
}

class ToggleTaskEvent extends TaskEvent {
  final String taskId;
  ToggleTaskEvent(this.taskId);
}

class ExportTasksEvent extends TaskEvent {}

class ImportTasksEvent extends TaskEvent {
  final List<Map<String, dynamic>> jsonData;
  ImportTasksEvent(this.jsonData);
}
