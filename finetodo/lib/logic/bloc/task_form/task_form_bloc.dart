import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../task/task_bloc.dart';
import '../../../data/models/task_model.dart';

part 'task_form_event.dart';
part 'task_form_state.dart';

class TaskFormBloc extends Bloc<TaskFormEvent, TaskFormState> {
  final TaskBloc _taskBloc;
  final Uuid _uuid = const Uuid();

  TaskFormBloc({required TaskBloc taskBloc})
    : _taskBloc = taskBloc,
      super(const TaskFormReadyState()) {
    on<LoadTaskForEditEvent>(_onLoadTaskForEdit);
    on<UpdateTaskFormEvent>(_onUpdateTaskForm);
    on<AddTaskFormEvent>(_onAddTaskForm);
    on<UpdateFormTitleEvent>(_onUpdateTitle);
    on<UpdateFormDescriptionEvent>(_onUpdateDescription);
    on<UpdateFormCategoryEvent>(_onUpdateCategory);
    on<UpdateFormDueDateEvent>(_onUpdateDueDate);
    on<UpdateFormRecurringEvent>(_onUpdateRecurring);
    on<UpdateFormRecurrencePatternEvent>(_onUpdateRecurrencePattern);
    on<ResetFormEvent>(_onResetForm);
  }

  /// Handles loading an existing task model for the form (Edit-only).
  Future<void> _onLoadTaskForEdit(
    LoadTaskForEditEvent event,
    Emitter<TaskFormState> emit,
  ) async {
    try {
      final taskBox = Hive.box<TaskModel>('tasks');
      final task = taskBox.get(event.taskId);

      debugPrint('Loaded task for edit: ${task?.title}');

      if (task != null) {
        emit(
          TaskFormLoadingState(
            initialTask: task,
            title: task.title,
            description: task.description,
            categoryId: task.category?.id,
            dueDate: task.dueDate,
            isRecurring: task.isRecurring,
            recurrencePattern: task.recurrencePattern,
          ),
        );
      } else {
        debugPrint('Task Not found');

        emit(TaskFormFailureState(errorMessage: 'Task not found.'));
      }
    } catch (e) {
      debugPrint('Task failed to load: $e');

      emit(
        TaskFormFailureState(
          errorMessage: 'Failed to load task: ${e.toString()}',
        ),
      );
    }
  }

  /// Handles updating an existing task and delegates to the main TaskBloc.
  Future<void> _onUpdateTaskForm(
    UpdateTaskFormEvent event,
    Emitter<TaskFormState> emit,
  ) async {
    if (state is! TaskFormLoadingState) return;

    final loadingState = state as TaskFormLoadingState;
    final task = loadingState.initialTask;

    // Validate title
    if (state.title == null || state.title!.isEmpty) {
      emit(TaskFormFailureState(errorMessage: 'Task name cannot be empty'));
      emit(
        TaskFormLoadingState(
          initialTask: task,
          title: state.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
      return;
    }

    emit(
      TaskFormSubmittingState(
        title: state.title,
        description: state.description,
        categoryId: state.categoryId,
        dueDate: state.dueDate,
        isRecurring: state.isRecurring,
        recurrencePattern: state.recurrencePattern,
      ),
    );

    try {
      final taskBox = Hive.box<TaskModel>('tasks');
      final existingTask = taskBox.get(task.id);

      if (existingTask == null) {
        emit(
          TaskFormFailureState(errorMessage: 'Cannot update: Task not found.'),
        );
        return;
      }

      // Handle category change: update category references and persist changes
      Category? updatedCategory = existingTask.category;
      if (state.categoryId != null &&
          state.categoryId != existingTask.category?.id) {
        final categoriesBox = Hive.box<Category>('categories');

        // Try to fetch the new category by key (we store categories by id)
        Category? newCat = categoriesBox.get(state.categoryId);
        // Fallback: search values if not keyed by id for some reason
        if (newCat == null) {
          try {
            newCat = categoriesBox.values.firstWhere(
              (c) => c.id == state.categoryId,
            );
          } catch (_) {
            newCat = null;
          }
        }

        if (newCat != null) {
          // Remove task id from old category (if present) and persist
          final oldCatId = existingTask.category?.id;
          if (oldCatId != null) {
            Category? oldCat = categoriesBox.get(oldCatId);
            if (oldCat == null) {
              // try values fallback
              try {
                oldCat = categoriesBox.values.firstWhere(
                  (c) => c.id == oldCatId,
                );
              } catch (_) {
                oldCat = null;
              }
            }

            if (oldCat != null) {
              final updatedOldTaskIds = List<String>.from(oldCat.taskIds);
              if (updatedOldTaskIds.remove(existingTask.id)) {
                final updatedOldCat = Category(
                  id: oldCat.id,
                  title: oldCat.title,
                  taskIds: updatedOldTaskIds,
                );
                await categoriesBox.put(updatedOldCat.id, updatedOldCat);
              }
            }
          }

          // Add task id to new category (if not already present) and persist
          final updatedNewTaskIds = List<String>.from(newCat.taskIds);
          if (!updatedNewTaskIds.contains(existingTask.id)) {
            updatedNewTaskIds.add(existingTask.id);
            final updatedNewCat = Category(
              id: newCat.id,
              title: newCat.title,
              taskIds: updatedNewTaskIds,
            );
            await categoriesBox.put(updatedNewCat.id, updatedNewCat);
            updatedCategory = updatedNewCat;
          } else {
            // even if no change, use canonical newCat instance
            updatedCategory = newCat;
          }
        }
      }

      final taskToSave = existingTask.copyWith(
        title: state.title ?? existingTask.title,
        description: state.description ?? existingTask.description,
        category: updatedCategory,
        dueDate: state.dueDate,
        isCompleted: existingTask.isCompleted,
        isRecurring: state.isRecurring,
        recurrencePattern: state.recurrencePattern,
      );

      _taskBloc.add(UpdateTaskEvent(taskToSave));
      emit(TaskFormSuccessState(successMessage: "Successfully updated task."));
    } catch (e) {
      emit(
        TaskFormFailureState(
          errorMessage: 'Failed to save task: ${e.toString()}',
        ),
      );
    }
  }

  /// Handles creating a new task and delegates to the main TaskBloc.
  Future<void> _onAddTaskForm(
    AddTaskFormEvent event,
    Emitter<TaskFormState> emit,
  ) async {
    // Validate title
    if (state.title == null || state.title!.isEmpty) {
      emit(TaskFormFailureState(errorMessage: 'Task name cannot be empty'));
      // Return to ready state with current data
      emit(
        TaskFormReadyState(
          title: state.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
      return;
    }

    emit(
      TaskFormSubmittingState(
        title: state.title,
        description: state.description,
        categoryId: state.categoryId,
        dueDate: state.dueDate,
        isRecurring: state.isRecurring,
        recurrencePattern: state.recurrencePattern,
      ),
    );

    try {
      // Get category from CategoryBloc (you'll need to implement this)
      // For now, create a basic category
      final category = Category(
        id: state.categoryId ?? 'general',
        title: 'General', // You'll need to get the actual title
      );

      final taskToSave = TaskModel(
        id: _uuid.v4(),
        title: state.title!,
        description: state.description ?? '',
        category: category,
        dueDate: state.dueDate,
        isCompleted: false,
        createdAt: DateTime.now(),
        isRecurring: state.isRecurring,
        recurrencePattern: state.recurrencePattern,
      );

      _taskBloc.add(AddTaskEvent(taskToSave));
      emit(TaskFormSuccessState(successMessage: "Successfully created task."));
    } catch (e) {
      emit(
        TaskFormFailureState(
          errorMessage: 'Failed to create task: ${e.toString()}',
        ),
      );
    }
  }

  /// Helper function for creating a TaskModel instance.
  TaskModel _createNewTask({
    required String title,
    String description = '',
    required Category category,
    DateTime? dueDate,
    bool isRecurring = false,
    String? recurrencePattern,
  }) {
    return TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      category: category,
      dueDate: dueDate,
      isCompleted: false,
      createdAt: DateTime.now(),
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
    );
  }

  /// Event handlers for form field updates
  void _onUpdateTitle(UpdateFormTitleEvent event, Emitter<TaskFormState> emit) {
    if (state is TaskFormLoadingState) {
      final loadingState = state as TaskFormLoadingState;
      emit(
        TaskFormLoadingState(
          initialTask: loadingState.initialTask,
          title: event.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    } else if (state is TaskFormReadyState ||
        state is TaskFormSubmittingState) {
      emit(
        TaskFormReadyState(
          title: event.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    }
  }

  void _onUpdateDescription(
    UpdateFormDescriptionEvent event,
    Emitter<TaskFormState> emit,
  ) {
    if (state is TaskFormLoadingState) {
      final loadingState = state as TaskFormLoadingState;
      emit(
        TaskFormLoadingState(
          initialTask: loadingState.initialTask,
          title: state.title,
          description: event.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    } else if (state is TaskFormReadyState ||
        state is TaskFormSubmittingState) {
      emit(
        TaskFormReadyState(
          title: state.title,
          description: event.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    }
  }

  void _onUpdateCategory(
    UpdateFormCategoryEvent event,
    Emitter<TaskFormState> emit,
  ) {
    if (state is TaskFormLoadingState) {
      final loadingState = state as TaskFormLoadingState;
      emit(
        TaskFormLoadingState(
          initialTask: loadingState.initialTask,
          title: state.title,
          description: state.description,
          categoryId: event.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    } else if (state is TaskFormReadyState ||
        state is TaskFormSubmittingState) {
      emit(
        TaskFormReadyState(
          title: state.title,
          description: state.description,
          categoryId: event.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    }
  }

  void _onUpdateDueDate(
    UpdateFormDueDateEvent event,
    Emitter<TaskFormState> emit,
  ) {
    if (state is TaskFormLoadingState) {
      final loadingState = state as TaskFormLoadingState;
      emit(
        TaskFormLoadingState(
          initialTask: loadingState.initialTask,
          title: state.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: event.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    } else if (state is TaskFormReadyState ||
        state is TaskFormSubmittingState) {
      emit(
        TaskFormReadyState(
          title: state.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: event.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    }
  }

  void _onUpdateRecurring(
    UpdateFormRecurringEvent event,
    Emitter<TaskFormState> emit,
  ) {
    if (state is TaskFormLoadingState) {
      final loadingState = state as TaskFormLoadingState;
      emit(
        TaskFormLoadingState(
          initialTask: loadingState.initialTask,
          title: state.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: event.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    } else if (state is TaskFormReadyState ||
        state is TaskFormSubmittingState) {
      emit(
        TaskFormReadyState(
          title: state.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: event.isRecurring,
          recurrencePattern: state.recurrencePattern,
        ),
      );
    }
  }

  void _onUpdateRecurrencePattern(
    UpdateFormRecurrencePatternEvent event,
    Emitter<TaskFormState> emit,
  ) {
    if (state is TaskFormLoadingState) {
      final loadingState = state as TaskFormLoadingState;
      emit(
        TaskFormLoadingState(
          initialTask: loadingState.initialTask,
          title: state.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: event.recurrencePattern,
        ),
      );
    } else if (state is TaskFormReadyState ||
        state is TaskFormSubmittingState) {
      emit(
        TaskFormReadyState(
          title: state.title,
          description: state.description,
          categoryId: state.categoryId,
          dueDate: state.dueDate,
          isRecurring: state.isRecurring,
          recurrencePattern: event.recurrencePattern,
        ),
      );
    }
  }

  void _onResetForm(ResetFormEvent event, Emitter<TaskFormState> emit) {
    emit(const TaskFormReadyState());
  }
}
