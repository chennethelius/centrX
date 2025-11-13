import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/event.dart';
import '../services/event_service.dart';

class EditEventPage extends StatefulWidget {
  final Event event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _durationController;
  final ImagePicker _picker = ImagePicker();

  File? _newMediaFile;
  String? _mediaType; // 'image' or 'video'
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  VideoPlayerController? _videoController;
  bool _keepExistingMedia = true;

  @override
  void initState() {
    super.initState();
    // Pre-populate fields from existing event
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _durationController = TextEditingController(text: widget.event.durationMinutes.toString());
    _selectedDate = widget.event.eventDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.event.eventDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _durationController.dispose();
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
        _newMediaFile = File(image.path);
        _mediaType = 'image';
        _videoController = null;
        _keepExistingMedia = false;
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
      setState(() {
        _newMediaFile = File(video.path);
        _mediaType = 'video';
        _videoController = controller;
        _keepExistingMedia = false;
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

  Future<void> _updateEvent() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final clubId = user.uid;

      // Create updated event object
      final updatedEvent = Event(
        likeCount: widget.event.likeCount,
        commentCount: widget.event.commentCount,
        isRsvped: widget.event.isRsvped,
        eventId: widget.event.eventId,
        ownerId: widget.event.ownerId,
        clubname: widget.event.clubname,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        createdAt: widget.event.createdAt, // Preserve original creation date
        eventDate: DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        ),
        mediaUrls: widget.event.mediaUrls, // Will be updated if new media is provided
        attendanceList: widget.event.attendanceList, // Preserve attendance
        rsvpList: widget.event.rsvpList, // Preserve RSVPs
        durationMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
        isQrEnabled: widget.event.isQrEnabled,
      );

      // Update event (with new media if provided)
      await EventService().updateEvent(
        clubId: clubId,
        event: updatedEvent,
        newMediaFile: _newMediaFile,
        deleteOldMedia: !_keepExistingMedia && _newMediaFile != null,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canUpdate = _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _locationController.text.isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null &&
        int.tryParse(_durationController.text.trim()) != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: const Text(
          'Edit Event',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaUploadSection(),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _titleController,
              hintText: 'Add a catchy title',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              hintText: 'Long description helps engagement.',
              fontSize: 16,
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 24),
            _buildDateTimeSection(),
            const SizedBox(height: 24),
            _buildLocationSection(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canUpdate ? _updateEvent : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.save, size: 20),
                    SizedBox(width: 8),
                    Text('Update Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaUploadSection() {
    final hasExistingMedia = widget.event.mediaUrls.isNotEmpty;
    final existingMediaUrl = hasExistingMedia ? widget.event.mediaUrls.first : null;
    final isExistingVideo = existingMediaUrl != null && existingMediaUrl.contains('video');

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _newMediaFile != null
          ? _buildNewMediaView()
          : (hasExistingMedia
              ? _buildExistingMediaView(existingMediaUrl!, isExistingVideo)
              : _buildMediaPlaceholder()),
    );
  }

  Widget _buildExistingMediaView(String mediaUrl, bool isVideo) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isVideo
              ? Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
                  ),
                )
              : Image.network(
                  mediaUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVideo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'VIDEO',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _selectMedia,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _keepExistingMedia,
                  onChanged: (value) {
                    setState(() {
                      _keepExistingMedia = value ?? true;
                    });
                  },
                  checkColor: Colors.white,
                  fillColor: MaterialStateProperty.all(Colors.white),
                ),
                const Text(
                  'Keep existing media',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewMediaView() => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _mediaType == 'image'
                ? Image.file(_newMediaFile!, width: double.infinity, height: 200, fit: BoxFit.cover)
                : (_videoController != null && _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : Container(width: double.infinity, height: 200, color: Colors.black)),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() {
                _newMediaFile = null;
                _videoController = null;
                _keepExistingMedia = true;
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (_mediaType == 'video')
            const Positioned(
              top: 8,
              left: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      );

  Widget _buildMediaPlaceholder() => InkWell(
        onTap: _selectMedia,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text('Add Photo or Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text('Max 1 minute for videos', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );

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
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: Colors.grey[400]),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Event Date & Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateTimeButton(
                label: _selectedDate == null
                    ? 'Select Date'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                icon: Icons.calendar_today_outlined,
                onTap: _selectDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateTimeButton(
                label: _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                icon: Icons.access_time_outlined,
                onTap: _selectTime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildDurationField()),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 21),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '0',
              ),
            ),
          ),
          const Text('min', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDateTimeButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.location_on_outlined, size: 20),
            SizedBox(width: 8),
            Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _locationController,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Add event location',
              hintStyle: TextStyle(fontSize: 16, color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

