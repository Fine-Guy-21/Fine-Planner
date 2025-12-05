import 'package:finetodo/logic/bloc/task/task_bloc.dart';
import 'package:flutter/material.dart';
import 'package:finetodo/data/models/task_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef TaskClickedCallback = void Function(String taskId);

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskClickedCallback onEdit;
  final TaskClickedCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.white,
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onLongPressStart: (details) {
          final overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              overlay.size.width - details.globalPosition.dx,
              overlay.size.height - details.globalPosition.dy,
            ),
            items: [
              PopupMenuItem(
                child: const Text('Edit'),
                onTap: () {
                  onEdit(task.id);
                },
              ),
              PopupMenuItem(
                child: const Text('Delete'),
                onTap: () {
                  onDelete(task.id);
                },
              ),
            ],
          );
        },
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) {
              context.read<TaskBloc>().add(ToggleTaskEvent(task.id));
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: task.description != "" ? Text(task.description) : null,

          trailing: PopupMenuButton(
            onSelected: (value) {
              if (value == 'edit') {
                // _showEditTaskDialog(context, task);
                onEdit(task.id);
              } else if (value == 'delete') {
                // context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
                onDelete(task.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
