import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/models/task_model.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  late Box<TaskModel> _taskBox;

  TaskBloc() : super(const TaskInitial()) {
    on<LoadTasksEvent>(_onLoadTasks);
    on<AddTaskEvent>(_onAddTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<ToggleTaskEvent>(_onToggleTask);
    on<ExportTasksEvent>(_onExportTasks);
    on<ImportTasksEvent>(_onImportTasks);
  }

  @override
  Future<void> close() async {
    await _taskBox.close();
    return super.close();
  }

  Future<void> _onLoadTasks(
    LoadTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      _taskBox = Hive.box<TaskModel>('tasks');
      final tasks = _taskBox.values.toList();
      emit(TasksLoadedState(tasks: tasks));
    } catch (e) {
      emit(TaskErrorState(message: e.toString()));
    }
  }

  // In your task_bloc.dart, update the _onAddTask method:
  Future<void> _onAddTask(AddTaskEvent event, Emitter<TaskState> emit) async {
    try {
      _taskBox = Hive.box<TaskModel>('tasks');

      // Ensure the category exists in categories box
      try {
        final catBox = Hive.box<Category>('categories');
        final catId = event.task.category.id;
        var cat = catBox.get(catId);

        // If category doesn't exist, create it or find an existing one
        if (cat == null) {
          // Try to find by title
          final existingCat = catBox.values.firstWhere(
            (c) => c.title == event.task.category.title,
            orElse: () => event.task.category,
          );

          // Update the task with the correct category
          final updatedTask = event.task.copyWith(category: existingCat);
          await _taskBox.put(updatedTask.id, updatedTask);

          // Update the category
          cat = existingCat;
        } else {
          await _taskBox.put(event.task.id, event.task);
        }

        // Update category's taskIds
        if (cat != null) {
          final updatedIds = List<String>.from(cat.taskIds);
          if (!updatedIds.contains(event.task.id)) {
            updatedIds.add(event.task.id);
          }
          final updated = Category(
            id: cat.id,
            title: cat.title,
            taskIds: updatedIds,
          );
          await catBox.put(cat.id, updated);
        }
      } catch (_) {
        // If categories box is not available, just add the task
        await _taskBox.put(event.task.id, event.task);
      }

      final tasks = _taskBox.values.toList();
      emit(TasksLoadedState(tasks: tasks));
    } catch (e) {
      emit(TaskErrorState(message: e.toString()));
    }
  }

  Future<void> _onUpdateTask(
    UpdateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      _taskBox = Hive.box<TaskModel>('tasks');

      // Get the original task to check if category changed
      final originalTask = _taskBox.get(event.task.id);

      // Update the task
      await _taskBox.put(event.task.id, event.task);

      // Handle category updates if category changed
      try {
        final catBox = Hive.box<Category>('categories');

        if (originalTask != null) {
          // If category changed, update both old and new categories
          if (originalTask.category.id != event.task.category.id) {
            // Remove task from old category
            final oldCat = catBox.get(originalTask.category.id);
            if (oldCat != null) {
              final updatedOldIds = List<String>.from(oldCat.taskIds)
                ..remove(event.task.id);
              final updatedOldCat = Category(
                id: oldCat.id,
                title: oldCat.title,
                taskIds: updatedOldIds,
              );
              await catBox.put(oldCat.id, updatedOldCat);
            }

            // Add task to new category
            final newCat = catBox.get(event.task.category.id);
            if (newCat != null) {
              final updatedNewIds = List<String>.from(newCat.taskIds)
                ..add(event.task.id);
              final updatedNewCat = Category(
                id: newCat.id,
                title: newCat.title,
                taskIds: updatedNewIds,
              );
              await catBox.put(newCat.id, updatedNewCat);
            } else {
              // If new category doesn't exist, create it
              final createdCat = Category(
                id: event.task.category.id,
                title: event.task.category.title,
                taskIds: [event.task.id],
              );
              await catBox.put(event.task.category.id, createdCat);
            }
          } else {
            // If category didn't change, just ensure the task is in the category's taskIds
            final currentCat = catBox.get(event.task.category.id);
            if (currentCat != null) {
              final updatedIds = List<String>.from(currentCat.taskIds);
              if (!updatedIds.contains(event.task.id)) {
                updatedIds.add(event.task.id);
              }
              final updatedCat = Category(
                id: currentCat.id,
                title: currentCat.title,
                taskIds: updatedIds,
              );
              await catBox.put(currentCat.id, updatedCat);
            }
          }
        } else {
          // If original task not found, just ensure the task is in the current category
          final currentCat = catBox.get(event.task.category.id);
          if (currentCat != null) {
            final updatedIds = List<String>.from(currentCat.taskIds);
            if (!updatedIds.contains(event.task.id)) {
              updatedIds.add(event.task.id);
            }
            final updatedCat = Category(
              id: currentCat.id,
              title: currentCat.title,
              taskIds: updatedIds,
            );
            await catBox.put(currentCat.id, updatedCat);
          }
        }
      } catch (e) {
        // Continue even if category update fails
      }

      final tasks = _taskBox.values.toList();
      emit(TasksLoadedState(tasks: tasks));
    } catch (e) {
      emit(TaskErrorState(message: e.toString()));
    }
  }

  Future<void> _onDeleteTask(
    DeleteTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      _taskBox = Hive.box<TaskModel>('tasks');
      // remove task from tasks box
      final task = _taskBox.get(event.taskId);
      await _taskBox.delete(event.taskId);
      // update category to remove this task id
      try {
        if (task != null) {
          final catBox = Hive.box<Category>('categories');
          final cat = catBox.get(task.category.id);
          if (cat != null) {
            final updatedIds = List<String>.from(cat.taskIds)
              ..remove(event.taskId);
            final updated = Category(
              id: cat.id,
              title: cat.title,
              taskIds: updatedIds,
            );
            await catBox.put(cat.id, updated);
          }
        }
      } catch (_) {}

      final tasks = _taskBox.values.toList();
      emit(TasksLoadedState(tasks: tasks));
    } catch (e) {
      emit(TaskErrorState(message: e.toString()));
    }
  }

  Future<void> _onToggleTask(
    ToggleTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      _taskBox = Hive.box<TaskModel>('tasks');
      final task = _taskBox.get(event.taskId);
      if (task != null) {
        final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
        await _taskBox.put(event.taskId, updatedTask);
      }

      final tasks = _taskBox.values.toList();
      emit(TasksLoadedState(tasks: tasks));
    } catch (e) {
      emit(TaskErrorState(message: e.toString()));
    }
  }

  Future<void> _onExportTasks(
    ExportTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      _taskBox = Hive.box<TaskModel>('tasks');
      final tasks = _taskBox.values.toList();

      final jsonData = tasks
          .map(
            (task) => {
              'id': task.id,
              'title': task.title,
              'description': task.description,
              'category': task.category,
              'dueDate': task.dueDate?.toIso8601String(),
              'isCompleted': task.isCompleted,
              'createdAt': task.createdAt.toIso8601String(),
              'isRecurring': task.isRecurring,
              'recurrencePattern': task.recurrencePattern,
            },
          )
          .toList();

      emit(TasksExportedState(jsonData: jsonData));
    } catch (e) {
      emit(TaskErrorState(message: e.toString()));
    }
  }

  Future<void> _onImportTasks(
    ImportTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      _taskBox = Hive.box<TaskModel>('tasks');

      for (var taskJson in event.jsonData) {
        final task = TaskModel(
          id: taskJson['id'],
          title: taskJson['title'],
          description: taskJson['description'],
          category: taskJson['category'] is Category
              ? taskJson['category']
              : Category(
                  id: taskJson['category'] ?? 'general',
                  title: taskJson['category']?.toString() ?? 'General',
                ),
          dueDate: taskJson['dueDate'] != null
              ? DateTime.parse(taskJson['dueDate'])
              : null,
          isCompleted: taskJson['isCompleted'] ?? false,
          createdAt: DateTime.parse(taskJson['createdAt']),
          isRecurring: taskJson['isRecurring'] ?? false,
          recurrencePattern: taskJson['recurrencePattern'],
        );

        await _taskBox.put(task.id, task);
        // update category taskIds
        try {
          final catBox = Hive.box<Category>('categories');
          final cat = catBox.get(task.category.id);
          if (cat != null) {
            final updatedIds = List<String>.from(cat.taskIds);
            if (!updatedIds.contains(task.id)) updatedIds.add(task.id);
            final updated = Category(
              id: cat.id,
              title: cat.title,
              taskIds: updatedIds,
            );
            await catBox.put(cat.id, updated);
          }
        } catch (_) {}
      }

      final tasks = _taskBox.values.toList();
      emit(TasksLoadedState(tasks: tasks));
    } catch (e) {
      emit(TaskErrorState(message: e.toString()));
    }
  }
}
