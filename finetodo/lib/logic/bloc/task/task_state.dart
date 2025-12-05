part of 'task_bloc.dart';

abstract class TaskState {
  const TaskState();
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TasksLoadedState extends TaskState {
  final List<TaskModel> tasks;
  const TasksLoadedState({required this.tasks});
}

class TasksExportedState extends TaskState {
  final List<Map<String, dynamic>> jsonData;
  const TasksExportedState({required this.jsonData});
}

class TaskErrorState extends TaskState {
  final String message;
  const TaskErrorState({required this.message});
}
