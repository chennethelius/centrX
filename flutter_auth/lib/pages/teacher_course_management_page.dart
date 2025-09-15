import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';

class TeacherCourseManagementPage extends StatefulWidget {
  const TeacherCourseManagementPage({super.key});

  @override
  State<TeacherCourseManagementPage> createState() => _TeacherCourseManagementPageState();
}

class _TeacherCourseManagementPageState extends State<TeacherCourseManagementPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _teachingClasses = [];
  bool _isLoading = false; // Start with false, only show loading when actually fetching

  @override
  void initState() {
    super.initState();
    _loadTeachingClasses();
  }

  Future<void> _loadTeachingClasses() async {
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final teacherDoc = await FirebaseFirestore.instance
          .collection('teachers_dir')
          .doc(user!.email)
          .get();

      if (teacherDoc.exists) {
        final teacherData = teacherDoc.data() ?? {};
        
        // Check for new session-based structure first
        final teachingSessions = List<Map<String, dynamic>>.from(
          teacherData['teachingSessions'] ?? []
        );
        
        if (teachingSessions.isNotEmpty) {
          // Use new session-based structure
          setState(() {
            _teachingClasses = teachingSessions.map((session) => {
              'courseCode': session['course_code'] ?? '',
              'courseTitle': session['course_title'] ?? '',
              'sectionNumber': session['section_number'] ?? '',
              'crn': session['crn'] ?? '',
              'meetingTimes': session['meeting_times'] ?? '[]',
              'credits': session['credits'] ?? '',
              'capacity': session['capacity'] ?? 0,
              'enrolled': session['enrolled'] ?? 0,
              'sessionId': session['session_id'] ?? '',
              // Keep backward compatibility fields
              'className': session['course_title'] ?? '',
              'classCode': session['course_code'] ?? '',
            }).toList();
            _isLoading = false;
          });
        } else {
          // Fallback to legacy structure for backward compatibility
          final teachingClasses = List<Map<String, dynamic>>.from(
            teacherData['teachingClasses'] ?? []
          );
          
          setState(() {
            _teachingClasses = teachingClasses;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading teaching classes: $e');
    }
  }

  Future<void> _addCourse() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourseSearchSheet(teacherEmail: user?.email ?? ''),
    );

    if (result != null) {
      await _loadTeachingClasses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${result['courseName']} to your teaching list'),
            backgroundColor: context.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _removeCourse(int index) async {
    final course = _teachingClasses[index];
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Course'),
        content: Text('Remove ${course['courseName']} from your teaching list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final updatedClasses = List<Map<String, dynamic>>.from(_teachingClasses);
        updatedClasses.removeAt(index);

        await FirebaseFirestore.instance
            .collection('teachers_dir')
            .doc(user!.email)
            .update({'teachingClasses': updatedClasses});

        await _loadTeachingClasses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${course['courseName']} from teaching list'),
              backgroundColor: context.warningOrange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to remove course'),
              backgroundColor: context.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.neutralWhite,
      appBar: AppBar(
        backgroundColor: context.neutralWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            IconlyBold.arrow_left_2,
            color: context.neutralBlack,
          ),
        ),
        title: Text(
          'Manage Courses',
          style: TextStyle(
            color: context.neutralBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teachingClasses.isEmpty
              ? _buildEmptyState()
              : _buildCoursesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconlyBold.document,
              size: 64,
              color: context.neutralGray,
            ),
            SizedBox(height: context.spacingL),
            Text(
              'No Classes Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.neutralBlack,
              ),
            ),
            SizedBox(height: context.spacingS),
            Text(
              'Search and add courses from the catalog to start managing your classes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.neutralMedium,
              ),
            ),
            SizedBox(height: context.spacingXL),
            ElevatedButton.icon(
              onPressed: _addCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentNavy,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacingL,
                  vertical: context.spacingM,
                ),
              ),
              icon: const Icon(IconlyBold.plus),
              label: const Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    return ListView.builder(
      padding: EdgeInsets.all(context.spacingL),
      itemCount: _teachingClasses.length,
      itemBuilder: (context, index) {
        final course = _teachingClasses[index];
        return _buildCourseCard(course, index);
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, int index) {
    final courseCode = course['courseCode'] ?? '';
    final courseName = course['courseName'] ?? 'Unknown Course';
    final department = course['department'] ?? '';
    final section = course['section'] ?? '';
    final crn = course['crn'] ?? '';
    final instructor = course['instructor'] ?? '';
    final credits = course['credits'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: context.spacingM),
      decoration: BoxDecoration(
        color: context.neutralWhite,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacingL),
        child: Row(
          children: [
            // Course icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.accentNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(context.radiusM),
              ),
              child: Icon(
                IconlyBold.document,
                color: context.accentNavy,
                size: 24,
              ),
            ),
            SizedBox(width: context.spacingM),

            // Course info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (courseCode.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.spacingS,
                            vertical: context.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: context.accentNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(context.radiusS),
                          ),
                          child: Text(
                            courseCode,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.accentNavy,
                            ),
                          ),
                        ),
                        if (section.isNotEmpty) ...[
                          SizedBox(width: context.spacingXS),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.spacingS,
                              vertical: context.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: context.infoBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(context.radiusS),
                            ),
                            child: Text(
                              'Sec $section',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.infoBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: context.spacingXS),
                  ],
                  Text(
                    courseName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.neutralBlack,
                    ),
                  ),
                  if (department.isNotEmpty || crn.isNotEmpty || credits.isNotEmpty) ...[
                    SizedBox(height: context.spacingXS),
                    Row(
                      children: [
                        if (department.isNotEmpty) ...[
                          Text(
                            department,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.neutralMedium,
                            ),
                          ),
                        ],
                        if (crn.isNotEmpty) ...[
                          if (department.isNotEmpty) 
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.neutralMedium,
                              ),
                            ),
                          Text(
                            'CRN $crn',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.neutralMedium,
                            ),
                          ),
                        ],
                        if (credits.isNotEmpty) ...[
                          if (department.isNotEmpty || crn.isNotEmpty)
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.neutralMedium,
                              ),
                            ),
                          Text(
                            '$credits credit${credits == '1' ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.neutralMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (instructor.isNotEmpty && instructor != 'TBA') ...[
                    SizedBox(height: context.spacingXS),
                    Row(
                      children: [
                        Icon(
                          IconlyLight.profile,
                          size: 14,
                          color: context.neutralMedium,
                        ),
                        SizedBox(width: context.spacingXS),
                        Text(
                          instructor,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.neutralMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Remove button
            IconButton(
              onPressed: () => _removeCourse(index),
              icon: Icon(
                IconlyBold.delete,
                color: context.errorRed,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseSearchSheet extends StatefulWidget {
  final String teacherEmail;

  const _CourseSearchSheet({required this.teacherEmail});

  @override
  State<_CourseSearchSheet> createState() => _CourseSearchSheetState();
}

class _CourseSearchSheetState extends State<_CourseSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _selectedCourse;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCourses(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Search course sessions for more detailed information
      final snapshot = await FirebaseFirestore.instance
          .collection('course_sessions')
          .orderBy('course_code')
          .get();

      final searchLower = query.toLowerCase();
      final results = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .where((session) {
        final code = (session['course_code'] ?? '').toLowerCase();
        final title = (session['course_title'] ?? '').toLowerCase();
        final dept = (session['department'] ?? '').toLowerCase();
        final instructor = (session['instructor_name'] ?? '').toLowerCase();
        
        return code.contains(searchLower) ||
               title.contains(searchLower) ||
               dept.contains(searchLower) ||
               instructor.contains(searchLower);
      }).take(50) // Limit the displayed results to 50 for performance
          .toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint('Error searching courses: $e');
    }
  }

  Future<void> _addCourseToTeaching() async {
    if (_selectedCourse == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) return;

    try {
      final courseData = _searchResults.firstWhere((c) => c['id'] == _selectedCourse);

      // Create session data with all the new fields
      final newSession = {
        'sessionId': _selectedCourse,
        'courseCode': courseData['code'] ?? '',
        'courseName': courseData['title'] ?? '',
        'department': courseData['dept'] ?? '',
        'section': courseData['section'] ?? '',
        'crn': courseData['crn'] ?? '',
        'instructor': courseData['instructor'] ?? '',
        'credits': courseData['credits'] ?? '',
        'addedAt': DateTime.now().toIso8601String(),
      };

      final teacherDoc = await FirebaseFirestore.instance
          .collection('teachers_dir')
          .doc(currentUser!.email)
          .get();

      final teacherData = teacherDoc.data() ?? {};
      
      // Handle both old structure (teachingClasses) and new structure (teachingSessions)
      final currentSessions = List<Map<String, dynamic>>.from(
        teacherData['teachingSessions'] ?? teacherData['teachingClasses'] ?? []
      );

      // Check if already teaching this specific session
      final isAlreadyTeaching = currentSessions.any((s) => 
        s['sessionId'] == _selectedCourse || s['courseId'] == _selectedCourse
      );

      if (isAlreadyTeaching) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Already teaching this course session'),
              backgroundColor: context.warningOrange,
            ),
          );
        }
        return;
      }

      currentSessions.add(newSession);

      // Update using the new teachingSessions field
      await FirebaseFirestore.instance
          .collection('teachers_dir')
          .doc(currentUser.email)
          .update({'teachingSessions': currentSessions});

      if (mounted) {
        Navigator.pop(context, newSession);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add course session'),
            backgroundColor: context.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: context.neutralWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.radiusXL),
          topRight: Radius.circular(context.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: context.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.neutralGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(context.spacingXL),
            child: Row(
              children: [
                Text(
                  'Add Course to Teaching List',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.neutralBlack,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    IconlyBold.close_square,
                    color: context.neutralBlack.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
            child: TextField(
              controller: _searchController,
              onChanged: _searchCourses,
              decoration: InputDecoration(
                hintText: 'Search courses (e.g., ACCT 1220, Business)',
                prefixIcon: Icon(
                  IconlyLight.search,
                  color: context.neutralMedium,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radiusL),
                  borderSide: BorderSide(color: context.neutralGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radiusL),
                  borderSide: BorderSide(color: context.accentNavy),
                ),
              ),
            ),
          ),

          SizedBox(height: context.spacingL),

          // Search results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IconlyBold.search,
                              size: 64,
                              color: context.neutralGray,
                            ),
                            SizedBox(height: context.spacingL),
                            Text(
                              'Search for courses to add',
                              style: TextStyle(
                                fontSize: 16,
                                color: context.neutralMedium,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final course = _searchResults[index];
                          final isSelected = _selectedCourse == course['id'];

                          return Container(
                            margin: EdgeInsets.only(bottom: context.spacingM),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(context.radiusL),
                                onTap: () {
                                  setState(() {
                                    _selectedCourse = isSelected ? null : course['id'];
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(context.spacingL),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected 
                                          ? context.accentNavy
                                          : context.neutralGray.withValues(alpha: 0.2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(context.radiusL),
                                    color: isSelected 
                                        ? context.accentNavy.withValues(alpha: 0.05)
                                        : Colors.transparent,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: context.spacingS,
                                              vertical: context.spacingXS,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.infoBlue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(context.radiusS),
                                            ),
                                            child: Text(
                                              course['code'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: context.infoBlue,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (isSelected)
                                            Icon(
                                              IconlyBold.tick_square,
                                              color: context.accentNavy,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: context.spacingS),
                                      Text(
                                        course['title'] ?? 'Unknown Course',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: context.neutralBlack,
                                        ),
                                      ),
                                      SizedBox(height: context.spacingXS),
                                      Row(
                                        children: [
                                          Text(
                                            course['dept'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: context.neutralBlack.withValues(alpha: 0.6),
                                            ),
                                          ),
                                          if (course['section'] != null) ...[
                                            Text(
                                              ' • Section ${course['section']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: context.infoBlue,
                                              ),
                                            ),
                                          ],
                                          if (course['crn'] != null) ...[
                                            Text(
                                              ' • CRN ${course['crn']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: context.neutralBlack.withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (course['instructor'] != null && course['instructor'].toString().isNotEmpty) ...[
                                        SizedBox(height: context.spacingXS),
                                        Row(
                                          children: [
                                            Icon(
                                              IconlyLight.profile,
                                              size: 16,
                                              color: context.neutralBlack.withValues(alpha: 0.6),
                                            ),
                                            SizedBox(width: context.spacingXS),
                                            Text(
                                              course['instructor'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: context.neutralBlack.withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (course['credits'] != null) ...[
                                        SizedBox(height: context.spacingXS),
                                        Text(
                                          '${course['credits']} credit${course['credits'] == '1' ? '' : 's'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: context.neutralBlack.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Add button
          if (_selectedCourse != null)
            Container(
              padding: EdgeInsets.all(context.spacingXL),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addCourseToTeaching,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentNavy,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: context.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.radiusL),
                    ),
                  ),
                  child: const Text(
                    'Add Course to Teaching List',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
