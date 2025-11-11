import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Task {
  String? objectId;
  String description;
  bool completed;
  bool active;
  String projectId;
  DateTime? createdAt;
  DateTime? updatedAt;

  Task({
    this.objectId,
    required this.description,
    this.completed = false,
    this.active = true,
    required this.projectId,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from ParseObject
  factory Task.fromParse(ParseObject parseObject) {
    return Task(
      objectId: parseObject.objectId,
      description: parseObject.get<String>('description') ?? '',
      completed: parseObject.get<bool>('completed') ?? false,
      active: parseObject.get<bool>('active') ?? true,
      projectId: parseObject.get<ParseObject>('project_id')?.objectId ?? '',
      createdAt: parseObject.createdAt,
      updatedAt: parseObject.updatedAt,
    );
  }

  // Convert to ParseObject
  ParseObject toParse() {
    final parseObject = ParseObject('task')
      ..set('description', description)
      ..set('completed', completed)
      ..set('active', active);

    if (objectId != null) {
      parseObject.objectId = objectId;
    }

    // Set project pointer
    final projectPointer = ParseObject('Project')..objectId = projectId;
    parseObject.set('project_id', projectPointer);

    return parseObject;
  }
}

