import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingEmptyStateWidget extends StatelessWidget {
  final VoidCallback onBrowseCars;

  const BookingEmptyStateWidget({
    super.key,
    required this.onBrowseCars,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cute character illustration
          Container(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Map background
                CustomPaint(
                  size: Size(280, 280),
                  painter: MapBackgroundPainter(
  lineColor: Theme.of(context).dividerColor,
),

                ),
                // Character
                Positioned(
                  top: 60,
                  child: Container(
                    width: 120,
                    height: 140,
                    child: CustomPaint(
                     painter: CharacterPainter(
                      faceColor: Theme.of(context).cardColor,
                    ),

                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No bookings yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'When you book a car, you\'ll see it here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: onBrowseCars,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).iconTheme.color,



              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Browse a Car',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the map background
class MapBackgroundPainter extends CustomPainter {
  final Color lineColor;

  MapBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Horizontal lines
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), linePaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), linePaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), linePaint);

    // Vertical lines
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), linePaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), linePaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), linePaint);

    // Buildings
    final buildingPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(size.width * 0.35, size.height * 0.55, 15, 20), buildingPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.55, size.height * 0.35, 12, 15), buildingPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.65, size.height * 0.72, 18, 22), buildingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for the cute character - using grey tones
class CharacterPainter extends CustomPainter {
  final Color faceColor;

  CharacterPainter({required this.faceColor});

  @override
  void paint(Canvas canvas, Size size) {
    final characterPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    // Body
    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.5, 0);
    bodyPath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.3,
      size.width * 0.5, size.height * 0.8,
    );
    bodyPath.quadraticBezierTo(
      size.width * 0.2, size.height * 0.3,
      size.width * 0.5, 0,
    );
    canvas.drawPath(bodyPath, characterPaint);

    // Bottom
    final bottomPath = Path();
    bottomPath.moveTo(size.width * 0.5, size.height * 0.8);
    bottomPath.lineTo(size.width * 0.4, size.height);
    bottomPath.lineTo(size.width * 0.6, size.height);
    bottomPath.close();
    canvas.drawPath(bottomPath, characterPaint);

    // Face
    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.35),
      size.width * 0.25,
      facePaint,
    );

    // Eyes
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.32), 4, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.32), 4, eyePaint);

    // Mouth
    final mouthPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    mouthPath.moveTo(size.width * 0.4, size.height * 0.42);
    mouthPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.38,
      size.width * 0.6, size.height * 0.42,
    );
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
