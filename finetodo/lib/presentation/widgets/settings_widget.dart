import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/api_bloc.dart';
import '../../logic/bloc/task/task_bloc.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  late TextEditingController _apiTokenController;

  @override
  void initState() {
    super.initState();
    _apiTokenController = TextEditingController();
  }

  @override
  void dispose() {
    _apiTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ApiBloc, ApiState>(
      listener: (context, state) {
        if (state is ApiExpiredState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'API token expired'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'API Configuration',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiTokenController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'GitHub OpenAI API Token',
                  border: OutlineInputBorder(),
                  hintText: 'Paste your API token here',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_apiTokenController.text.isNotEmpty) {
                    context.read<ApiBloc>().add(
                      InitializeApiEvent(_apiTokenController.text),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API token updated')),
                    );
                  }
                },
                child: const Text('Update API Token'),
              ),
              const SizedBox(height: 24),
              BlocBuilder<ApiBloc, ApiState>(
                builder: (context, state) {
                  if (state is ApiReadyState) {
                    return Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✓ API Status: Active'),
                            Text('Days remaining: ${state.daysRemaining}'),
                            const SizedBox(height: 8),
                            const Text('API expires: December 25, 2025'),
                          ],
                        ),
                      ),
                    );
                  } else if (state is ApiExpiredState) {
                    return Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✗ API Status: Expired'),
                            const Text('Please update your API token'),
                            const SizedBox(height: 8),
                            const Text('API expired: December 25, 2025'),
                          ],
                        ),
                      ),
                    );
                  }
                  return const Text('Initialize API to see status');
                },
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
          ),
        ),
      ),
    );
  }
}
