import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  // Use Category instead of String
  @HiveField(3)
  final Category category;

  @HiveField(4)
  final DateTime? dueDate;

  @HiveField(5)
  final bool isCompleted;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final bool isRecurring;

  @HiveField(8)
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly'

  TaskModel({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
    this.isRecurring = false,
    this.recurrencePattern,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    Category? category,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    bool? isRecurring,
    String? recurrencePattern,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
    );
  }
}

@HiveType(typeId: 1)
class Category {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<String> taskIds;

  Category({String? id, required this.title, List<String>? taskIds})
    : id = id ?? const Uuid().v4(),
      taskIds = taskIds ?? [];
}
