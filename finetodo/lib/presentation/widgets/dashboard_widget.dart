import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../logic/bloc/task/task_bloc.dart';
// import '../../data/models/task_model.dart';

class DashboardWidget extends StatelessWidget {
  const DashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TasksLoadedState) {
          final completedCount = state.tasks.where((t) => t.isCompleted).length;
          final pendingCount = state.tasks.where((t) => !t.isCompleted).length;
          final totalTasks = state.tasks.length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        title: 'Completed',
                        value: completedCount.toString(),
                        color: Colors.green,
                      ),
                      _StatCard(
                        title: 'Pending',
                        value: pendingCount.toString(),
                        color: Colors.orange,
                      ),
                      _StatCard(
                        title: 'Total',
                        value: totalTasks.toString(),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (totalTasks > 0) ...[
                    Text(
                      'Task Distribution',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: completedCount.toDouble(),
                              title: '$completedCount',
                              color: Colors.green,
                            ),
                            PieChartSectionData(
                              value: pendingCount.toDouble(),
                              title: '$pendingCount',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Data Management',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<TaskBloc>().add(ExportTasksEvent());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tasks exported')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export Tasks'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Show file picker or paste JSON
                      },
                      icon: const Icon(Icons.upload),
                      label: const Text('Import Tasks'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}
