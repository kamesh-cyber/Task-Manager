import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  final Project project;

  TaskListScreen({required this.project});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      if (widget.project.objectId != null) {
        final tasks = await TaskService.getTasksByProjectId(widget.project.objectId!);
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading tasks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateTaskDialog([Task? editTask]) {
    final descController = TextEditingController(text: editTask?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editTask == null ? 'Create Task' : 'Edit Task'),
        content: TextField(
          controller: descController,
          decoration: InputDecoration(
            labelText: 'Task Description',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final description = descController.text.trim();
              if (description.isEmpty) {
                _showSnackBar('Please enter a task description');
                return;
              }

              Navigator.pop(context);

              if (editTask == null) {
                await _createTask(description);
              } else {
                await _updateTask(editTask, description);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: Text(editTask == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTask(String description) async {
    if (widget.project.objectId == null) return;

    try {
      final task = Task(
        description: description,
        projectId: widget.project.objectId!,
      );

      final response = await TaskService.createTask(task);
      if (response.success) {
        _showSnackBar('Task created successfully');
        await _loadTasks();
      } else {
        _showSnackBar('Failed to create task: ${response.error?.message}');
      }
    } catch (e) {
      _showSnackBar('Error creating task: $e');
    }
  }

  Future<void> _updateTask(Task task, String description) async {
    try {
      task.description = description;

      final response = await TaskService.updateTask(task);
      if (response.success) {
        _showSnackBar('Task updated successfully');
        await _loadTasks();
      } else {
        _showSnackBar('Failed to update task: ${response.error?.message}');
      }
    } catch (e) {
      _showSnackBar('Error updating task: $e');
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      final response = await TaskService.toggleTaskCompletion(task);
      if (response.success) {
        await _loadTasks();
      } else {
        _showSnackBar('Failed to update task: ${response.error?.message}');
      }
    } catch (e) {
      _showSnackBar('Error updating task: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    if (task.objectId == null) return;

    try {
      final response = await TaskService.deleteTask(task.objectId!);
      if (response.success) {
        _showSnackBar('Task deleted successfully');
        await _loadTasks();
      } else {
        _showSnackBar('Failed to delete task: ${response.error?.message}');
      }
    } catch (e) {
      _showSnackBar('Error deleting task: $e');
    }
  }

  // New helper to confirm before soft deleting
  void _confirmDelete(Task task) {
    if (task.objectId == null) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteTask(task);
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            if (widget.project.description.isNotEmpty)
              Text(
                widget.project.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(),
        icon: Icon(Icons.add),
        label: Text('New Task'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, size: 80, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the button below to create one',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Dismissible(
                        key: ValueKey(task.objectId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteTask(task),
                        child: Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: task.completed,
                                  onChanged: (_) => _toggleTaskCompletion(task),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    task.description,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: task.completed ? Colors.grey[600] : Colors.black87,
                                      decoration: task.completed
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      decorationThickness: 2,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20),
                                  onPressed: () => _showCreateTaskDialog(task),
                                  color: Colors.grey[600],
                                ),
                                // New delete button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  color: Colors.red[600],
                                  tooltip: 'Delete task',
                                  onPressed: () => _confirmDelete(task),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
