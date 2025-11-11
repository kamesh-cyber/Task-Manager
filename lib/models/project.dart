import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
class Project {
  String? objectId;
  String title;
  String description;
  String userId;
  DateTime? createdAt;
  DateTime? updatedAt;
  Project({
    this.objectId,
    required this.title,
    this.description = '',
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });
  factory Project.fromParse(ParseObject parseObject) {
    return Project(
      objectId: parseObject.objectId,
      title: parseObject.get<String>('title') ?? '',
      description: parseObject.get<String>('description') ?? '',
      userId: parseObject.get<ParseObject>('user_id')?.objectId ?? '',
      createdAt: parseObject.createdAt,
      updatedAt: parseObject.updatedAt,
    );
  }
  ParseObject toParse() {
    final parseObject = ParseObject('Project')
      ..set('title', title)
      ..set('description', description);
    if (objectId != null) {
      parseObject.objectId = objectId;
    }
    final userPointer = ParseObject('_User')..objectId = userId;
    parseObject.set('user_id', userPointer);
    return parseObject;
  }
}
