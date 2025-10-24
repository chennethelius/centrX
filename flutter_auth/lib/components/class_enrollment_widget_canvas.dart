import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';
import '../services/canvas_student_service.dart';

class ClassEnrollmentWidgetCanvas extends StatefulWidget {
  final String userId;

  const ClassEnrollmentWidgetCanvas({
    required this.userId,
    super.key,
  });

  @override
  State<ClassEnrollmentWidgetCanvas> createState() =>
      _ClassEnrollmentWidgetCanvasState();
}

class _ClassEnrollmentWidgetCanvasState
    extends State<ClassEnrollmentWidgetCanvas> {
  bool isLoading = true;
  bool canvasConnected = false;
  List<Map<String, dynamic>> canvasClasses = [];
  List<Map<String, dynamic>> manualClasses = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          canvasConnected = userData['canvasConnected'] as bool? ?? false;
          canvasClasses = List<Map<String, dynamic>>.from(
            userData['canvasClasses'] as List<dynamic>? ?? [],
          );
          manualClasses = List<Map<String, dynamic>>.from(
            userData['manualClasses'] as List<dynamic>? ?? [],
          );
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint('Error loading classes: $e');
    }
  }

  Future<void> _connectCanvas() async {
    final canvasUrl =
        await _showCanvasInputDialog('Canvas URL', 'https://slu.instructure.com');
    if (canvasUrl == null) return;

    final apiToken = await _showCanvasInputDialog('Canvas API Token', '');
    if (apiToken == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Connecting to Canvas...'),
        content: SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final isValid = await CanvasStudentService.testCanvasConnection(
        canvasUrl: canvasUrl,
        apiToken: apiToken,
      );

      if (!isValid) {
        if (mounted) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Connection Failed'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('❌ Invalid Canvas credentials'),
                  SizedBox(height: 16),
                  Text(
                    'Please check:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('• Canvas URL is correct (https://slu.instructure.com)'),
                  Text('• API token was copied completely'),
                  Text('• Token has not expired'),
                  Text('• Your Canvas account has API access'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final courses = await CanvasStudentService.fetchStudentCourses(
        canvasUrl: canvasUrl,
        apiToken: apiToken,
      );

      await CanvasStudentService.saveCanvasCredentials(
        canvasUrl: canvasUrl,
        apiToken: apiToken,
      );

      await CanvasStudentService.importCoursesToFirestore(courses);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Connected! Found ${courses.length} courses'),
            backgroundColor: context.successGreen,
          ),
        );
        _loadClasses();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshCanvas() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Refreshing from Canvas...'),
        content: SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      await CanvasStudentService.refreshCoursesFromCanvas();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Courses refreshed'),
            backgroundColor: context.successGreen,
          ),
        );
        _loadClasses();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeClass(String canvasId) async {
    try {
      await CanvasStudentService.removeCanvasClass(canvasId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class removed'),
            backgroundColor: context.successGreen,
          ),
        );
        _loadClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addManualClass() async {
    final code = await _showCanvasInputDialog('Course Code', 'e.g., CS101');
    if (code == null) return;

    final name =
        await _showCanvasInputDialog('Course Name', 'e.g., Computer Science 101');
    if (name == null) return;

    final instructor = await _showCanvasInputDialog('Instructor Name', '');
    if (instructor == null) return;

    try {
      await CanvasStudentService.addManualClass(
        code: code,
        name: name,
        instructor: instructor,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Class added'),
            backgroundColor: context.successGreen,
          ),
        );
        _loadClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeManualClass(String classId) async {
    try {
      await CanvasStudentService.removeManualClass(classId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class removed'),
            backgroundColor: context.successGreen,
          ),
        );
        _loadClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _showCanvasInputDialog(String title, String hint) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.radiusL),
            ),
          ),
          obscureText: title.contains('Token'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!canvasConnected) ...[
            _buildNotConnectedState(),
          ] else ...[
            _buildConnectedState(),
          ],
          SizedBox(height: context.spacingL),
          if (canvasClasses.isNotEmpty) ...[
            Text(
              'Canvas Classes (${canvasClasses.length})',
              style: context.theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.neutralBlack,
              ),
            ),
            SizedBox(height: context.spacingM),
            ..._buildCanvasClassList(),
            SizedBox(height: context.spacingL),
          ],
          if (manualClasses.isNotEmpty) ...[
            Text(
              'Manual Classes',
              style: context.theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.neutralBlack,
              ),
            ),
            SizedBox(height: context.spacingM),
            ..._buildManualClassList(),
          ],
          SizedBox(height: context.spacingL),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addManualClass,
                  icon: const Icon(IconlyBold.plus),
                  label: const Text('Add Manual'),
                ),
              ),
              if (canvasConnected) ...[
                SizedBox(width: context.spacingM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _refreshCanvas,
                    icon: const Icon(IconlyBold.arrow_right_2),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotConnectedState() {
    return Container(
      padding: EdgeInsets.all(context.spacingL),
      decoration: BoxDecoration(
        color: context.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconlyBold.notification,
                color: context.warningOrange,
              ),
              SizedBox(width: context.spacingM),
              Expanded(
                child: Text(
                  'Canvas Not Connected',
                  style: context.theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.warningOrange,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingM),
          Text(
            'Sync your Canvas classes to auto-import all your courses.',
            style: context.theme.textTheme.bodySmall?.copyWith(
              color: context.neutralDark,
            ),
          ),
          SizedBox(height: context.spacingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _connectCanvas,
              icon: const Icon(Icons.link),
              label: const Text('Connect Canvas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedState() {
    return Container(
      padding: EdgeInsets.all(context.spacingL),
      decoration: BoxDecoration(
        color: context.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            IconlyBold.tick_square,
            color: context.successGreen,
          ),
          SizedBox(width: context.spacingM),
          Expanded(
            child: Text(
              '✅ Canvas Connected (${canvasClasses.length} classes)',
              style: context.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCanvasClassList() {
    return canvasClasses
        .map((course) => Padding(
              padding: EdgeInsets.only(bottom: context.spacingM),
              child: Container(
                padding: EdgeInsets.all(context.spacingM),
                decoration: BoxDecoration(
                  color: context.secondaryLight,
                  borderRadius: BorderRadius.circular(context.radiusM),
                  border: Border.all(color: context.neutralGray),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['name'] as String? ?? 'Unknown',
                            style: context.theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.neutralBlack,
                            ),
                          ),
                          SizedBox(height: context.spacingXS),
                          Text(
                            course['code'] as String? ?? '',
                            style: context.theme.textTheme.bodySmall?.copyWith(
                              color: context.neutralGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(IconlyBold.close_square),
                      color: context.errorRed,
                      onPressed: () =>
                          _removeClass(course['canvasId'] as String),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  List<Widget> _buildManualClassList() {
    return manualClasses
        .map((course) => Padding(
              padding: EdgeInsets.only(bottom: context.spacingM),
              child: Container(
                padding: EdgeInsets.all(context.spacingM),
                decoration: BoxDecoration(
                  color: context.secondaryLight,
                  borderRadius: BorderRadius.circular(context.radiusM),
                  border: Border.all(color: context.neutralGray),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  course['name'] as String? ?? 'Unknown',
                                  style: context.theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.neutralBlack,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.spacingS,
                                  vertical: context.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: context.infoBlue.withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(context.radiusS),
                                ),
                                child: Text(
                                  'Manual',
                                  style: context.theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: context.infoBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.spacingXS),
                          Text(
                            '${course['code'] as String? ?? ''} • ${course['instructor'] as String? ?? ''}',
                            style: context.theme.textTheme.bodySmall?.copyWith(
                              color: context.neutralGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(IconlyBold.close_square),
                      color: context.errorRed,
                      onPressed: () =>
                          _removeManualClass(course['id'] as String),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }
}
