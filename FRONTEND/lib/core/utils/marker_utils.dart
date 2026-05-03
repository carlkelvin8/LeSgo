import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerUtils {
  /// Creates a custom colored marker icon
  static Future<BitmapDescriptor> createColoredMarker(Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    const double width = 40.0;
    const double height = 50.0;
    const double circleRadius = 15.0;
    
    // Draw the pin shape
    final path = Path();
    
    // Top circle
    path.addOval(Rect.fromCircle(
      center: Offset(width / 2, circleRadius),
      radius: circleRadius,
    ));
    
    // Bottom triangle/point
    path.moveTo(width / 2 - circleRadius, circleRadius);
    path.lineTo(width / 2, height);
    path.lineTo(width / 2 + circleRadius, circleRadius);
    path.close();
    
    // Fill with solid color - no border
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
  
  /// Predefined marker colors
  static Future<BitmapDescriptor> get purpleMarker => 
      createColoredMarker(const Color(0xFF9C27B0)); // Purple
  
  static Future<BitmapDescriptor> get violetMarker => 
      createColoredMarker(const Color(0xFF7B1FA2)); // Violet
  
  static Future<BitmapDescriptor> get redMarker => 
      createColoredMarker(const Color(0xFFEA4335)); // Google Maps Red
  
  static Future<BitmapDescriptor> get blueMarker => 
      createColoredMarker(const Color(0xFF4285F4)); // Google Maps Blue
  
  static Future<BitmapDescriptor> get greenMarker => 
      createColoredMarker(const Color(0xFF34A853)); // Google Maps Green
  
  static Future<BitmapDescriptor> get yellowMarker => 
      createColoredMarker(const Color(0xFFFBBC04)); // Google Maps Yellow
  
  static Future<BitmapDescriptor> get cyanMarker => 
      createColoredMarker(const Color(0xFF00BCD4)); // Cyan
}
