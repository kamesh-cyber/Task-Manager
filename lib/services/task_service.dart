import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/task.dart';

class TaskService {
  // Create a new task
  static Future<ParseResponse> createTask(Task task) async {
    final parseObject = task.toParse();
    return await parseObject.save();
  }

  // Get all tasks for a project
  static Future<List<Task>> getTasksByProjectId(String projectId) async {
    final queryBuilder = QueryBuilder<ParseObject>(ParseObject('task'));

    // Filter by project_id pointer and active status
    final projectPointer = ParseObject('Project')..objectId = projectId;
    queryBuilder.whereEqualTo('project_id', projectPointer);
    queryBuilder.whereEqualTo('active', true);

    // Order by creation date
    queryBuilder.orderByDescending('createdAt');

    final response = await queryBuilder.query();

    if (response.success && response.results != null) {
      return response.results!.map((e) => Task.fromParse(e as ParseObject)).toList();
    }
    return [];
  }

  // Update a task
  static Future<ParseResponse> updateTask(Task task) async {
    final parseObject = task.toParse();
    return await parseObject.save();
  }

  // Delete a task (soft delete by setting active to false)
  static Future<ParseResponse> deleteTask(String objectId) async {
    final parseObject = ParseObject('task')
      ..objectId = objectId
      ..set('active', false);
    return await parseObject.save();
  }

  // Toggle task completion
  static Future<ParseResponse> toggleTaskCompletion(Task task) async {
    task.completed = !task.completed;
    return await updateTask(task);
  }
}

