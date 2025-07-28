import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/event.dart';
import '../services/post_service.dart';

class PostEventPage extends StatefulWidget {
  const PostEventPage({super.key});

  @override
  State<PostEventPage> createState() => _PostEventPageState();
}

class _PostEventPageState extends State<PostEventPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedMedia;
  String? _mediaType; // 'image' or 'video'
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (image != null) {
      _videoController?.dispose();
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
        _videoController = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 1),
    );
    if (video != null) {
      _videoController?.dispose();
      final controller = VideoPlayerController.file(File(video.path));
      await controller.initialize();
      controller.setLooping(true);
      controller.play();
      setState(() {
        _selectedMedia = File(video.path);
        _mediaType = 'video';
        _videoController = controller;
      });
    }
  }

  void _selectMedia() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Media',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Choose Video (Max 1 min)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveAsDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event saved as draft')),
    );
  }

  void _showMediaRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Required'),
        content: const Text('Please add a photo or video to your event.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _postEvent() async {
  if (_selectedMedia == null) {
    _showMediaRequiredDialog();
    return;
  }

  // 1) Show a loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final user = FirebaseAuth.instance.currentUser!;
    final clubId = user.uid; 

    // 2) Generate a new eventId
    final eventRef = FirebaseFirestore.instance
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .doc();
    final eventId = eventRef.id;

    // 3) Upload the media file
    final storageRef = FirebaseStorage.instance
        .ref('clubs/$clubId/events/$eventId/media/$eventId');
    final uploadTask = storageRef.putFile(_selectedMedia!);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // 4) Construct your Event model
    final event = Event(
      eventId:        eventId,
      ownerId:       user.uid,
      username:      user.displayName ?? 'Unknown',
      title:         _titleController.text.trim(),
      description:   _descriptionController.text.trim(),
      location:      _locationController.text.trim(),
      createdAt:     DateTime.now(),
      eventDate:     DateTime(
                       _selectedDate!.year,
                       _selectedDate!.month,
                       _selectedDate!.day,
                       _selectedTime!.hour,
                       _selectedTime!.minute,
                     ),
      mediaUrls:     [downloadUrl],
      attendanceList: [],
    );

    // 5) Write both event + top‑level media docs in one batch
    await PostService().createEventWithMedia(
      clubId: clubId,
      event:  event,
    );

    // 6) Success!
    Navigator.of(context).pop(); // dismiss loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event posted successfully!')),
    );
    Navigator.pop(context); // go back
  } catch (e) {
    Navigator.of(context).pop(); // dismiss loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error posting event: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final bool canPost = _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _locationController.text.isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.black)),
        title: const Text('Create Event', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: _saveAsDraft, child: const Text('Drafts', style: TextStyle(color: Colors.grey, fontSize: 16))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildMediaUploadSection(),
          const SizedBox(height: 24),
          _buildTextField(controller: _titleController, hintText: 'Add a catchy title', fontSize: 24, fontWeight: FontWeight.w600, maxLines: 2),
          const SizedBox(height: 16),
          _buildTextField(controller: _descriptionController, hintText: 'Long description helps engagement.', fontSize: 16, maxLines: 5, minLines: 3),
          const SizedBox(height: 24),
          _buildDateTimeSection(),
          const SizedBox(height: 24),
          _buildLocationSection(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canPost ? _postEvent : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1744),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.auto_awesome, size: 20),
                SizedBox(width: 8),
                Text('Post Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildMediaUploadSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
      child: _selectedMedia == null ? InkWell(onTap: _selectMedia, borderRadius: BorderRadius.circular(12), child: _buildMediaPlaceholder()) : _buildSelectedMediaView(),
    );
  }

  Widget _buildMediaPlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(50)), child: Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey[600])),
          const SizedBox(height: 12),
          Text('Add Photo or Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text('Max 1 minute for videos', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      );

  Widget _buildSelectedMediaView() => Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _mediaType == 'image'
              ? Image.file(_selectedMedia!, width: double.infinity, height: 200, fit: BoxFit.cover)
              : (_videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))
                  : Container(width: double.infinity, height: 200, color: Colors.black)),
        ),
        Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => setState(() { _selectedMedia = null; _videoController = null; }), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20)))),
        if (_mediaType == 'video')
          const Positioned(
            top: 8,
            left: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.all(Radius.circular(12))),
              child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
      ]);

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    int maxLines = 1,
    int? minLines,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: Colors.black87),
      decoration: InputDecoration(hintText: hintText, hintStyle: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: Colors.grey[400]), border: InputBorder.none, contentPadding: EdgeInsets.zero),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Event Date & Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildDateTimeButton(label: _selectedDate == null ? 'Select Date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}', icon: Icons.calendar_today_outlined, onTap: _selectDate)),
        const SizedBox(width: 12),
        Expanded(child: _buildDateTimeButton(label: _selectedTime == null ? 'Select Time' : _selectedTime!.format(context), icon: Icons.access_time_outlined, onTap: _selectTime)),
      ]),
    ]);
  }

  Widget _buildDateTimeButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
        child: Row(children: [Icon(icon, size: 20, color: Colors.grey[600]), const SizedBox(width: 8), Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Colors.black87)))]),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: const [Icon(Icons.location_on_outlined, size: 20), SizedBox(width: 8), Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87))]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
        child: TextField(
          controller: _locationController,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(hintText: 'Add event location', hintStyle: TextStyle(fontSize: 16, color: Colors.grey[500]), border: InputBorder.none, contentPadding: EdgeInsets.zero),
        ),
      ),
    ]);
  }
}

