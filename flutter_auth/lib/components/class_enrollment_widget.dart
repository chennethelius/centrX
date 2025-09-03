import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';

class ClassEnrollmentWidget extends StatefulWidget {
  final String userId;

  const ClassEnrollmentWidget({
    required this.userId,
    super.key,
  });

  @override
  State<ClassEnrollmentWidget> createState() => _ClassEnrollmentWidgetState();
}

class _ClassEnrollmentWidgetState extends State<ClassEnrollmentWidget> {
  List<Map<String, dynamic>> enrolledClasses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrolledClasses();
  }

  Future<void> _loadEnrolledClasses() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final classes = userData['enrolledClasses'] as List<dynamic>? ?? [];
        setState(() {
          enrolledClasses = classes.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error loading enrolled classes: $e');
    }
  }

  Future<void> _addNewClass() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClassSearchSheet(userId: widget.userId),
    );

    if (result != null) {
      setState(() {
        enrolledClasses.add(result);
      });
    }
  }

  Future<void> _removeClass(int index) async {
    try {
      final updatedClasses = List<Map<String, dynamic>>.from(enrolledClasses);
      updatedClasses.removeAt(index);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'enrolledClasses': updatedClasses});

      setState(() {
        enrolledClasses = updatedClasses;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class removed successfully'),
            backgroundColor: context.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to remove class'),
            backgroundColor: context.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'My Classes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.neutralBlack,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _addNewClass,
              icon: Container(
                padding: EdgeInsets.all(context.spacingS),
                decoration: BoxDecoration(
                  color: context.accentNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
                child: Icon(
                  IconlyBold.plus,
                  color: context.accentNavy,
                  size: 20,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: context.spacingL),

        // Classes List
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (enrolledClasses.isEmpty)
          _buildEmptyState()
        else
          _buildClassesList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(context.spacingXL),
      decoration: BoxDecoration(
        color: context.neutralGray.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            IconlyBold.document,
            size: 48,
            color: context.neutralGray,
          ),
          SizedBox(height: context.spacingM),
          Text(
            'No classes enrolled',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.neutralBlack.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: context.spacingS),
          Text(
            'Tap the + button to add your classes',
            style: TextStyle(
              fontSize: 14,
              color: context.neutralBlack.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList() {
    return SizedBox(
      height: 200, // Fixed height to show approximately 2 class cards
      child: ListView.builder(
        itemCount: enrolledClasses.length,
        itemBuilder: (context, index) {
          final classData = enrolledClasses[index];
          return _buildClassCard(classData, index);
        },
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData, int index) {
    final courseCode = classData['courseCode'] ?? '';
    final courseName = classData['courseName'] ?? 'Unknown Course';
    final instructorName = classData['instructorName'] ?? 'Unknown Instructor';
    final department = classData['department'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: context.spacingM),
      padding: EdgeInsets.all(context.spacingL),
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
      child: Row(
        children: [
          // Course icon
          Container(
            padding: EdgeInsets.all(context.spacingM),
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
                Row(
                  children: [
                    if (courseCode.isNotEmpty) ...[
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
                          courseCode,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.infoBlue,
                          ),
                        ),
                      ),
                      SizedBox(width: context.spacingS),
                    ],
                    if (department.isNotEmpty)
                      Text(
                        department,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.neutralBlack.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: context.spacingS),
                Text(
                  courseName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack,
                  ),
                ),
                SizedBox(height: context.spacingXS),
                Row(
                  children: [
                    Icon(
                      IconlyBold.profile,
                      size: 14,
                      color: context.neutralBlack.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: context.spacingXS),
                    Expanded(
                      child: Text(
                        instructorName,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () => _removeClass(index),
            icon: Icon(
              IconlyBold.delete,
              color: context.errorRed.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassSearchSheet extends StatefulWidget {
  final String userId;

  const _ClassSearchSheet({required this.userId});

  @override
  State<_ClassSearchSheet> createState() => _ClassSearchSheetState();
}

class _ClassSearchSheetState extends State<_ClassSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _instructorResults = [];
  bool _isSearching = false;
  String? _selectedCourse;
  String? _selectedInstructor;

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
      // Get all courses - remove the limit to search through entire catalog
      final snapshot = await FirebaseFirestore.instance
          .collection('courses_catalog')
          .orderBy('code') // Add ordering for consistent results
          .get();

      final searchLower = query.toLowerCase();
      final results = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .where((course) {
        final code = (course['code'] ?? '').toLowerCase();
        final title = (course['title'] ?? '').toLowerCase();
        final dept = (course['dept'] ?? '').toLowerCase();
        
        return code.contains(searchLower) ||
               title.contains(searchLower) ||
               dept.contains(searchLower);
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

  Future<void> _searchInstructors(String query) async {
    if (query.isEmpty) {
      setState(() {
        _instructorResults = [];
      });
      return;
    }

    try {
      // Get all instructors - remove the limit to search through entire directory
      final snapshot = await FirebaseFirestore.instance
          .collection('teachers_dir')
          .orderBy('fullName') // Add ordering for consistent results
          .get();

      final searchLower = query.toLowerCase();
      final results = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .where((teacher) {
        final fullName = (teacher['fullName'] ?? '').toLowerCase();
        final email = (teacher['email'] ?? '').toLowerCase();
        final department = (teacher['department'] ?? '').toLowerCase();
        
        return fullName.contains(searchLower) ||
               email.contains(searchLower) ||
               department.contains(searchLower);
      }).take(30) // Limit displayed results to 30 for performance
          .toList();

      setState(() {
        _instructorResults = results;
      });
    } catch (e) {
      debugPrint('Error searching instructors: $e');
    }
  }

  Future<void> _enrollInClass() async {
    if (_selectedCourse == null || _selectedInstructor == null) return;

    try {
      final courseData = _searchResults.firstWhere((c) => c['id'] == _selectedCourse);
      final instructorData = _instructorResults.firstWhere((i) => i['id'] == _selectedInstructor);

      final newClass = {
        'courseId': _selectedCourse,
        'courseCode': courseData['code'] ?? '',
        'courseName': courseData['title'] ?? '',
        'department': courseData['dept'] ?? '',
        'instructorId': _selectedInstructor,
        'instructorName': instructorData['fullName'] ?? '',
        'instructorEmail': instructorData['email'] ?? '',
        'enrolledAt': DateTime.now().toIso8601String(),
      };

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      final userData = userDoc.data() ?? {};
      final currentClasses = List<Map<String, dynamic>>.from(
        userData['enrolledClasses'] ?? []
      );

      // Check if already enrolled
      final isAlreadyEnrolled = currentClasses.any((c) => 
        c['courseId'] == _selectedCourse && c['instructorId'] == _selectedInstructor
      );

      if (isAlreadyEnrolled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Already enrolled in this class'),
              backgroundColor: context.warningOrange,
            ),
          );
        }
        return;
      }

      currentClasses.add(newClass);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'enrolledClasses': currentClasses});

      if (mounted) {
        Navigator.pop(context, newClass);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to enroll in class'),
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
                  'Add New Class',
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

          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: context.accentNavy,
                    unselectedLabelColor: context.neutralBlack.withValues(alpha: 0.5),
                    indicatorColor: context.accentNavy,
                    tabs: const [
                      Tab(text: '1. Select Course'),
                      Tab(text: '2. Select Instructor'),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCourseSearch(),
                        _buildInstructorSearch(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Enroll button
          Container(
            padding: EdgeInsets.all(context.spacingXL),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedCourse != null && _selectedInstructor != null)
                    ? _enrollInClass
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentNavy,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: context.spacingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.radiusL),
                  ),
                ),
                child: const Text(
                  'Enroll in Class',
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

  Widget _buildCourseSearch() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(context.spacingXL),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchCourses(value);
            },
            decoration: InputDecoration(
              hintText: 'Search courses (e.g., ACCT 1220, Business)',
              prefixIcon: Icon(IconlyLight.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radiusL),
              ),
            ),
          ),
        ),

        // Results
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
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
                              _selectedCourse = course['id'];
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
                                  course['title'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.neutralBlack,
                                  ),
                                ),
                                SizedBox(height: context.spacingXS),
                                Text(
                                  course['dept'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.neutralBlack.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInstructorSearch() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(context.spacingXL),
          child: TextField(
            onChanged: _searchInstructors,
            decoration: InputDecoration(
              hintText: 'Search instructors (name, email, department)',
              prefixIcon: Icon(IconlyLight.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radiusL),
              ),
            ),
          ),
        ),

        // Results
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
            itemCount: _instructorResults.length,
            itemBuilder: (context, index) {
              final instructor = _instructorResults[index];
              final isSelected = _selectedInstructor == instructor['id'];
              
              return Container(
                margin: EdgeInsets.only(bottom: context.spacingM),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(context.radiusL),
                    onTap: () {
                      setState(() {
                        _selectedInstructor = instructor['id'];
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
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: context.accentNavy.withValues(alpha: 0.1),
                            child: Text(
                              _getInitials(instructor['fullName'] ?? ''),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.accentNavy,
                              ),
                            ),
                          ),
                          SizedBox(width: context.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  instructor['fullName'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.neutralBlack,
                                  ),
                                ),
                                SizedBox(height: context.spacingXS),
                                Text(
                                  instructor['department'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.neutralBlack.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  instructor['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.neutralBlack.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              IconlyBold.tick_square,
                              color: context.accentNavy,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
