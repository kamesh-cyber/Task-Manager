import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/project.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';
import 'login_screen.dart';
import 'task_list_screen.dart';

class ProjectListScreen extends StatefulWidget {
  @override
  _ProjectListScreenState createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;
  String? _userEmail;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndProjects();
  }

  Future<void> _loadUserAndProjects() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        setState(() {
          _userEmail = user.get<String>('email');
          _userId = user.objectId;
        });
        await _loadProjects();
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      _showSnackBar('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProjects() async {
    if (_userId == null) return;

    try {
      final projects = await ProjectService.getProjectsByUserId(_userId!);
      setState(() {
        _projects = projects;
      });
    } catch (e) {
      _showSnackBar('Error loading projects: $e');
    }
  }

  void _showCreateProjectDialog([Project? editProject]) {
    final titleController = TextEditingController(text: editProject?.title ?? '');
    final descController = TextEditingController(text: editProject?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editProject == null ? 'Create Project' : 'Edit Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Project Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                _showSnackBar('Please enter a project title');
                return;
              }

              Navigator.pop(context);

              if (editProject == null) {
                await _createProject(title, descController.text.trim());
              } else {
                await _updateProject(editProject, title, descController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: Text(editProject == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _createProject(String title, String description) async {
    if (_userId == null) return;

    try {
      final project = Project(
        title: title,
        description: description,
        userId: _userId!,
      );

      final response = await ProjectService.createProject(project);
      if (response.success) {
        _showSnackBar('Project created successfully');
        await _loadProjects();
      } else {
        _showSnackBar('Failed to create project: ${response.error?.message}');
      }
    } catch (e) {
      _showSnackBar('Error creating project: $e');
    }
  }

  Future<void> _updateProject(Project project, String title, String description) async {
    try {
      project.title = title;
      project.description = description;

      final response = await ProjectService.updateProject(project);
      if (response.success) {
        _showSnackBar('Project updated successfully');
        await _loadProjects();
      } else {
        _showSnackBar('Failed to update project: ${response.error?.message}');
      }
    } catch (e) {
      _showSnackBar('Error updating project: $e');
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.title}"? This will also delete all associated tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && project.objectId != null) {
      try {
        final response = await ProjectService.deleteProject(project.objectId!);
        if (response.success) {
          _showSnackBar('Project deleted successfully');
          await _loadProjects();
        } else {
          _showSnackBar('Failed to delete project: ${response.error?.message}');
        }
      } catch (e) {
        _showSnackBar('Error deleting project: $e');
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _openProject(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskListScreen(project: project),
      ),
    ).then((_) => _loadProjects()); // Refresh when returning
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
            Text('Projects', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            if (_userEmail != null)
              Text(
                _userEmail!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(),
        icon: Icon(Icons.add),
        label: Text('New Project'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No projects yet',
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
                  onRefresh: _loadProjects,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      final project = _projects[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: InkWell(
                          onTap: () => _openProject(project),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.folder, color: Colors.indigo),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (project.description.isNotEmpty) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          project.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showCreateProjectDialog(project);
                                    } else if (value == 'delete') {
                                      _deleteProject(project);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
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

