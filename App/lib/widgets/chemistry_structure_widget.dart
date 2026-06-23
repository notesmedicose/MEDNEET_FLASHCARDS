import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChemistryStructureWidget extends StatelessWidget {
  final String structureKey;
  final double size;

  const ChemistryStructureWidget({
    super.key,
    required this.structureKey,
    this.size = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black87;

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: CustomPaint(
        size: Size(size - 24, size - 24),
        painter: ChemistryStructurePainter(
          structureKey: structureKey,
          color: color,
        ),
      ),
    );
  }
}

class ChemistryStructurePainter extends CustomPainter {
  final String structureKey;
  final Color color;

  ChemistryStructurePainter({
    required this.structureKey,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double R = math.min(size.width, size.height) * 0.3;

    switch (structureKey.toLowerCase()) {
      case 'benzene':
        _drawBenzene(canvas, center, R, paint);
        break;
      case 'phenol':
        _drawBenzeneWithSubstituent(canvas, center, R, paint, 'OH');
        break;
      case 'aniline':
        _drawBenzeneWithSubstituent(canvas, center, R, paint, 'NH₂');
        break;
      case 'toluene':
        _drawBenzeneWithSubstituent(canvas, center, R, paint, 'CH₃');
        break;
      case 'benzaldehyde':
        _drawBenzeneWithSubstituent(canvas, center, R, paint, 'CHO');
        break;
      case 'benzoic_acid':
        _drawBenzeneWithSubstituent(canvas, center, R, paint, 'COOH');
        break;
      case 'chlorobenzene':
        _drawBenzeneWithSubstituent(canvas, center, R, paint, 'Cl');
        break;
      case 'nitrobenzene':
        _drawBenzeneWithSubstituent(canvas, center, R, paint, 'NO₂');
        break;
      case 'anisole':
        _drawBenzeneWithSubstituent(canvas, center, R, paint, 'OCH₃');
        break;
      case 'benzene_diazonium':
        _drawBenzeneWithSubstituent(canvas, center, R, paint, 'N₂⁺ Cl⁻');
        break;
      case 'cumene':
        _drawCumene(canvas, center, R, paint);
        break;
      case 'salicylic_acid':
        _drawSalicylic(canvas, center, R, paint, isAcid: true);
        break;
      case 'salicylaldehyde':
        _drawSalicylic(canvas, center, R, paint, isAcid: false);
        break;
      case 'cyclohexane':
        _drawCyclohexane(canvas, center, R, paint);
        break;
      case 'naphthalene':
        _drawNaphthalene(canvas, center, R, paint);
        break;
      case 'pyridine':
        _drawPyridine(canvas, center, R, paint);
        break;
      case 'furan':
        _drawPentacycle(canvas, center, R, paint, 'O');
        break;
      case 'thiophene':
        _drawPentacycle(canvas, center, R, paint, 'S');
        break;
      case 'pyrrole':
        _drawPentacycle(canvas, center, R, paint, 'NH');
        break;
      default:
        _drawBenzene(canvas, center, R, paint);
    }
  }

  // --- Drawing Helpers ---

  List<Offset> _getHexagonPoints(Offset center, double R) {
    final angles = [
      -math.pi / 2,     // 0: Top
      -math.pi / 6,     // 1: Top-Right
      math.pi / 6,      // 2: Bottom-Right
      math.pi / 2,      // 3: Bottom
      5 * math.pi / 6,  // 4: Bottom-Left
      -5 * math.pi / 6, // 5: Top-Left
    ];
    return angles.map((a) => center + Offset(R * math.cos(a), R * math.sin(a))).toList();
  }

  void _drawDoubleBond(Canvas canvas, Offset p1, Offset p2, Offset center, Paint paint) {
    canvas.drawLine(p1, p2, paint);
    const double k = 0.8;
    final p1Inner = center + (p1 - center) * k;
    final p2Inner = center + (p2 - center) * k;
    canvas.drawLine(p1Inner, p2Inner, paint);
  }

  void _drawBenzene(Canvas canvas, Offset center, double R, Paint paint) {
    final pts = _getHexagonPoints(center, R);
    for (int i = 0; i < 6; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % 6];
      if (i % 2 == 0) {
        _drawDoubleBond(canvas, p1, p2, center, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  void _drawBenzeneWithSubstituent(Canvas canvas, Offset center, double R, Paint paint, String label) {
    // Shift center slightly down to accommodate the top label
    final adjustedCenter = center + const Offset(0, 10);
    _drawBenzene(canvas, adjustedCenter, R, paint);

    final pts = _getHexagonPoints(adjustedCenter, R);
    final topVertex = pts[0];

    // Draw bond going up
    final labelPos = topVertex - const Offset(0, 16);
    canvas.drawLine(topVertex, labelPos, paint);

    // Draw text label above the bond
    _drawLabel(canvas, label, labelPos - const Offset(0, 8), TextAlign.center);
  }

  void _drawCumene(Canvas canvas, Offset center, double R, Paint paint) {
    final adjustedCenter = center + const Offset(0, 10);
    _drawBenzene(canvas, adjustedCenter, R, paint);

    final pts = _getHexagonPoints(adjustedCenter, R);
    final topVertex = pts[0];

    // Draw isopropyl group (branching lines)
    final branchCenter = topVertex - const Offset(0, 18);
    canvas.drawLine(topVertex, branchCenter, paint);

    final leftBranch = branchCenter + Offset(-15, -12);
    final rightBranch = branchCenter + Offset(15, -12);
    canvas.drawLine(branchCenter, leftBranch, paint);
    canvas.drawLine(branchCenter, rightBranch, paint);
  }

  void _drawSalicylic(Canvas canvas, Offset center, double R, Paint paint, {required bool isAcid}) {
    final adjustedCenter = center + const Offset(-10, 15);
    _drawBenzene(canvas, adjustedCenter, R, paint);

    final pts = _getHexagonPoints(adjustedCenter, R);
    
    // OH at top (V0)
    final topVertex = pts[0];
    final ohPos = topVertex - const Offset(0, 16);
    canvas.drawLine(topVertex, ohPos, paint);
    _drawLabel(canvas, 'OH', ohPos - const Offset(0, 8), TextAlign.center);

    // COOH or CHO at top-right (V1)
    final orthoVertex = pts[1];
    final orthoAngle = -math.pi / 6;
    final orthoPos = orthoVertex + Offset(16 * math.cos(orthoAngle), 16 * math.sin(orthoAngle));
    canvas.drawLine(orthoVertex, orthoPos, paint);
    _drawLabel(canvas, isAcid ? 'COOH' : 'CHO', orthoPos + const Offset(12, 0), TextAlign.left);
  }

  void _drawCyclohexane(Canvas canvas, Offset center, double R, Paint paint) {
    final pts = _getHexagonPoints(center, R);
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(pts[i], pts[(i + 1) % 6], paint);
    }
  }

  void _drawNaphthalene(Canvas canvas, Offset center, double R, Paint paint) {
    final shiftX = R * math.cos(math.pi / 6);
    final leftCenter = center - Offset(shiftX, 0);
    final rightCenter = center + Offset(shiftX, 0);

    final leftPts = _getHexagonPoints(leftCenter, R);
    final rightPts = _getHexagonPoints(rightCenter, R);

    // Draw left ring
    for (int i = 0; i < 6; i++) {
      final p1 = leftPts[i];
      final p2 = leftPts[(i + 1) % 6];
      // Double bonds in left ring: V5->V0 (top-left slant), V3->V4 (bottom-left slant), V1->V2 (shared vertical edge)
      if (i == 5 || i == 3 || i == 1) {
        _drawDoubleBond(canvas, p1, p2, leftCenter, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }

    // Draw right ring (middle vertical edge is already drawn as i=1 of left ring)
    for (int i = 0; i < 6; i++) {
      if (i == 4 || i == 5) continue; // Skip shared vertical edge and its adjacent vertices
      final p1 = rightPts[i];
      final p2 = rightPts[(i + 1) % 6];
      // Double bonds in right ring: V0->V1 (top-right slant), V2->V3 (bottom-right slant)
      if (i == 0 || i == 2) {
        _drawDoubleBond(canvas, p1, p2, rightCenter, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  void _drawPyridine(Canvas canvas, Offset center, double R, Paint paint) {
    final pts = _getHexagonPoints(center, R);
    
    // Draw edges except those connected directly to N (V3)
    canvas.drawLine(pts[0], pts[1], paint); // V0 -> V1
    canvas.drawLine(pts[4], pts[5], paint); // V4 -> V5
    canvas.drawLine(pts[5], pts[0], paint); // V5 -> V0

    // V3 is Nitrogen
    final nPos = pts[3];
    _drawLabel(canvas, 'N', nPos, TextAlign.center);

    // Bonds to N from V2 and V4 (stop slightly before center of N)
    final double stopRatio = 0.8;
    final bondToN1 = pts[2] + (nPos - pts[2]) * stopRatio;
    final bondToN2 = pts[4] + (nPos - pts[4]) * stopRatio;
    canvas.drawLine(pts[1], pts[2], paint); // V1 -> V2
    canvas.drawLine(pts[2], bondToN1, paint);
    canvas.drawLine(pts[4], bondToN2, paint);

    // Pyridine Double Bonds (alternating): Side 0 (V0->V1), Side 2 (V2->N), Side 4 (V4->V5)
    // Draw inner lines
    const double k = 0.8;
    // Side 0 (V0->V1)
    final p0Inner = center + (pts[0] - center) * k;
    final p1Inner = center + (pts[1] - center) * k;
    canvas.drawLine(p0Inner, p1Inner, paint);
    
    // Side 4 (V4->V5)
    final p4Inner = center + (pts[4] - center) * k;
    final p5Inner = center + (pts[5] - center) * k;
    canvas.drawLine(p4Inner, p5Inner, paint);

    // Side 2 (V2->N)
    final p2Inner = center + (pts[2] - center) * k;
    final nInner = center + (bondToN1 - center) * k;
    canvas.drawLine(p2Inner, nInner, paint);
  }

  void _drawPentacycle(Canvas canvas, Offset center, double R, Paint paint, String heteroatom) {
    final adjustedCenter = center + const Offset(0, 8);
    // Regular pentagon angles (pointing down at 90 deg)
    final angles = [
      18 * math.pi / 180,   // 0: Middle-Right
      90 * math.pi / 180,   // 1: Bottom (Heteroatom)
      162 * math.pi / 180,  // 2: Middle-Left
      234 * math.pi / 180,  // 3: Top-Left
      306 * math.pi / 180,  // 4: Top-Right
    ];

    final pts = angles.map((a) => adjustedCenter + Offset(R * math.cos(a), R * math.sin(a))).toList();

    // Draw V3 -> V4 (horizontal top edge)
    canvas.drawLine(pts[3], pts[4], paint);
    // Draw V3 -> V2 (upper-left edge)
    canvas.drawLine(pts[3], pts[2], paint);
    // Draw V4 -> V0 (upper-right edge)
    canvas.drawLine(pts[4], pts[0], paint);

    // V1 is the Heteroatom (O, S, or NH)
    final hPos = pts[1];
    _drawLabel(canvas, heteroatom, hPos, TextAlign.center);

    // Draw bonds to heteroatom stopping slightly before it
    final double stopRatio = 0.8;
    final bondToH1 = pts[2] + (hPos - pts[2]) * stopRatio;
    final bondToH2 = pts[0] + (hPos - pts[0]) * stopRatio;
    canvas.drawLine(pts[2], bondToH1, paint);
    canvas.drawLine(pts[0], bondToH2, paint);

    // Double bonds at V3->V2 and V4->V0
    const double k = 0.8;
    // V3->V2
    final p3Inner = adjustedCenter + (pts[3] - adjustedCenter) * k;
    final p2Inner = adjustedCenter + (pts[2] - adjustedCenter) * k;
    canvas.drawLine(p3Inner, p2Inner, paint);

    // V4->V0
    final p4Inner = adjustedCenter + (pts[4] - adjustedCenter) * k;
    final p0Inner = adjustedCenter + (pts[0] - adjustedCenter) * k;
    canvas.drawLine(p4Inner, p0Inner, paint);
  }

  void _drawLabel(Canvas canvas, String label, Offset pos, TextAlign align) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    Offset drawPos;
    if (align == TextAlign.center) {
      drawPos = pos - Offset(textPainter.width / 2, textPainter.height / 2);
    } else if (align == TextAlign.left) {
      drawPos = pos - Offset(0, textPainter.height / 2);
    } else {
      drawPos = pos - Offset(textPainter.width, textPainter.height / 2);
    }
    textPainter.paint(canvas, drawPos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
