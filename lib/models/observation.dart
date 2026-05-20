import 'dart:math';

class ControlPoint {
  final String id;
  final double easting;
  final double northing;
  final double height;

  ControlPoint({
    required this.id, 
    required this.easting, 
    required this.northing, 
    required this.height,
  });
}

class RawObservation {
  final String fromId;
  final String toId;
  final double horizontalAngle; // Radians
  final double zenithAngle;     // Radians
  final double slopeDistance;   // Meters
  final double instrumentHeight; // Meters
  final double targetHeight;     // Meters

  RawObservation({
    required this.fromId,
    required this.toId,
    required this.horizontalAngle,
    required this.zenithAngle,
    required this.slopeDistance,
    required this.instrumentHeight,
    required this.targetHeight,
  });

  /// Applies physical field corrections to raw total station measurements
  Map<String, double> reduceObservation({double tempC = 20.0, double pressureHpa = 1013.25}) {
    // 1. Atmospheric Correction (PPM)
    double e = 12.0; // Standard partial water vapor pressure
    double ppm = 282.324 - (0.2948 * pressureHpa) / (1 + 0.00366 * tempC) - (0.0004126 * e) / (1 + 0.00366 * tempC);
    double correctedSD = slopeDistance * (1.0 + ppm / 1000000.0);

    // 2. Earth Curvature and Refraction Corrections
    double k = 0.13;          // Refraction coefficient
    double R = 6371000.0;     // Earth Radius (meters)
    
    double hd = correctedSD * sin(zenithAngle);
    double deltaHRaw = (correctedSD * cos(zenithAngle)) + instrumentHeight - targetHeight;
    double deltaH = deltaHRaw + ((1.0 - k) / (2 * R)) * pow(hd, 2);

    return {
      'HD': hd,
      'DeltaH': deltaH,
      'CorrectedSD': correctedSD
    };
  }
}