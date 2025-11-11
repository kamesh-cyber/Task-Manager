import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/project.dart';

class ProjectService {
  // Create a new project
  static Future<ParseResponse> createProject(Project project) async {
    final parseObject = project.toParse();
    return await parseObject.save();
  }

  // Get all projects for a user
  static Future<List<Project>> getProjectsByUserId(String userId) async {
    final queryBuilder = QueryBuilder<ParseObject>(ParseObject('Project'));

    // Filter by user_id pointer
    final userPointer = ParseObject('_User')..objectId = userId;
    queryBuilder.whereEqualTo('user_id', userPointer);

    // Order by creation date
    queryBuilder.orderByDescending('createdAt');

    final response = await queryBuilder.query();

    if (response.success && response.results != null) {
      return response.results!.map((e) => Project.fromParse(e as ParseObject)).toList();
    }
    return [];
  }

  // Update a project
  static Future<ParseResponse> updateProject(Project project) async {
    final parseObject = project.toParse();
    return await parseObject.save();
  }

  // Delete a project
  static Future<ParseResponse> deleteProject(String objectId) async {
    final parseObject = ParseObject('Project')..objectId = objectId;
    return await parseObject.delete();
  }

  // Get a single project by ID
  static Future<Project?> getProjectById(String objectId) async {
    final queryBuilder = QueryBuilder<ParseObject>(ParseObject('Project'));
    queryBuilder.whereEqualTo('objectId', objectId);

    final response = await queryBuilder.query();

    if (response.success && response.results != null && response.results!.isNotEmpty) {
      return Project.fromParse(response.results!.first as ParseObject);
    }
    return null;
  }
}

