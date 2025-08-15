import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import 'confirmation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _startReportFlow() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('التقاط صورة'),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('تسجيل فيديو'),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      await _handleUpload(File(image.path), mediaType: 'image');
    } catch (e) {
      _showSnack('حدث خطأ أثناء التقاط الصورة');
    }
  }

  Future<void> _captureVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video == null) return;
      await _handleUpload(File(video.path), mediaType: 'video');
    } catch (e) {
      _showSnack('حدث خطأ أثناء تسجيل الفيديو');
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('الرجاء تفعيل خدمات الموقع (GPS)');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack('تم رفض صلاحية الموقع');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack('صلاحية الموقع مرفوضة نهائيًا. الرجاء تفعيلها من الإعدادات.');
      return false;
    }

    return true;
  }

  Future<void> _handleUpload(File file, {required String mediaType}) async {
    if (!await _ensureLocationPermission()) return;

    try {
      setState(() => _isUploading = true);
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final nowIso = DateTime.now().toIso8601String();

      final result = await ApiService.uploadReport(
        filePath: file.path,
        latitude: pos.latitude,
        longitude: pos.longitude,
        mediaType: mediaType,
        reportedAtIso: nowIso,
      );

      if (!mounted) return;
      _showSnack('تم إرسال البلاغ بنجاح');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(reportId: result['id']?.toString()),
        ),
      );
    } catch (e) {
      _showSnack('فشل إرسال البلاغ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('y/MM/dd – HH:mm').format(DateTime.now());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مرشد'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'عند مشاهدة فعل غير قانوني، يمكنك الإبلاغ فورًا بالتصوير وإرسال الموقع.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _isUploading
                    ? Column(
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('جارٍ رفع البلاغ...')
                        ],
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.report),
                        label: const Text('بدء البلاغ'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(220, 48),
                        ),
                        onPressed: _startReportFlow,
                      ),
                const SizedBox(height: 16),
                Text('التاريخ: $now'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}