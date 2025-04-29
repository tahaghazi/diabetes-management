import 'package:flutter/material.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FullImageScreen extends StatelessWidget {
  final String imageUrl;

  const FullImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عرض الصورة'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.appBarGradient,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Center(
          child: kIsWeb || imageUrl.isEmpty
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'الصورة غير متاحة',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                )
              : InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading full image: $error');
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 100, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'فشل تحميل الصورة',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}