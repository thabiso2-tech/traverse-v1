import 'dart:math';
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';
import '../models/observation.dart';

class AdjustmentEngine {
  final List<ControlPoint> controlPoints;
  final List<RawObservation> observations;
  final Map<String, List<double>> instrumentSpecs;

  AdjustmentEngine({
    required this.controlPoints,
    required this.observations,
    required this.instrumentSpecs,
  });

  Map<String, dynamic> computeAdjustment() {
    Set<String> allPoints = {};
    for (var obs in observations) {
      allPoints.add(obs.fromId);
      allPoints.add(obs.toId);
    }
    Set<String> fixedPoints = controlPoints.map((c) => c.id).toSet();
    List<String> unknownPoints = allPoints.difference(fixedPoints).toList();

    if (fixedPoints.isEmpty) {
      throw Exception("Matrix Anchor Fault: You must input at least 1 known Control Point.");
    }

    Map<String, int> indexMap = {};
    for (int i = 0; i < unknownPoints.length; i++) {
      indexMap[unknownPoints[i]] = i * 3;
    }

    // Initialize approximate coordinate map
    Map<String, Vector> coordMap = {};
    for (var key in indexMap.keys) {
      coordMap[key] = Vector.fromList([
        controlPoints.first.easting + 15.0, 
        controlPoints.first.northing + 15.0, 
        controlPoints.first.height
      ]);
    }

    bool converged = false;
    int iterations = 0;
    int maxIterations = 8;
    
    int numObs = observations.length * 3; 
    int numParams = unknownPoints.length * 3;

    Matrix? X; Matrix? A; Matrix? W; Matrix? L;

    while (!converged && iterations < maxIterations) {
      List<List<double>> aRows = [];
      List<double> wDiag = [];
      List<double> lRows = [];

      for (var obs in observations) {
        var reductions = obs.reduceObservation();
        double sdCorr = reductions['CorrectedSD']!;
        
        Vector posFrom = _getCoord(obs.fromId, coordMap);
        Vector posTo = _getCoord(obs.toId, coordMap);

        double dE = posTo[0] - posFrom[0];
        double dN = posTo[1] - posFrom[1];
        double dH = posTo[2] - posFrom[2];
        
        double calcHD = sqrt(dE * dE + dN * dN);
        double calcSD = sqrt(dE * dE + dN * dN + dH * dH);
        double azimuth = atan2(dE, dN);
        double calcZ = acos(dH / calcSD);

        // Slope Distance Equation Matrix Row
        List<double> aSD = List.filled(numParams, 0.0);
        _applyJacobianRow(aSD, obs.fromId, obs.toId, indexMap, 
            -sin(azimuth) * sin(calcZ), -cos(azimuth) * sin(calcZ), -cos(calcZ));
        aRows.add(aSD);
        lRows.add(obs.slopeDistance - calcSD);
        wDiag.add(1.0 / pow(instrumentSpecs['SD']![0] + (instrumentSpecs['SD']![1] * 1e-6 * obs.slopeDistance), 2));

        // Zenith Angle Equation Matrix Row
        List<double> aZ = List.filled(numParams, 0.0);
        _applyJacobianRow(aZ, obs.fromId, obs.toId, indexMap,
            (sin(azimuth) * cos(calcZ)) / calcHD, (cos(azimuth) * cos(calcZ)) / calcHD, -sin(calcZ) / calcHD);
        aRows.add(aZ);
        lRows.add(obs.zenithAngle - calcZ);
        wDiag.add(1.0 / pow(instrumentSpecs['VA']![0] * (pi / 648000.0), 2));

        // Horizontal Angle Equation Matrix Row
        List<double> aHA = List.filled(numParams, 0.0);
        _applyJacobianRow(aHA, obs.fromId, obs.toId, indexMap,
            cos(azimuth) / calcHD, -sin(azimuth) / calcHD, 0.0);
        aRows.add(aHA);
        lRows.add(obs.horizontalAngle - azimuth);
        wDiag.add(1.0 / pow(instrumentSpecs['HA']![0] * (pi / 648000.0), 2));
      }

      A = Matrix.fromList(aRows);
      W = Matrix.diagonal(wDiag);
      L = Matrix.fromList(lRows.map((e) => [e]).toList());

      var AT = A.transpose();
      var N = AT * W * A;
      var U = AT * W * L;
      
      X = N.inverse() * U;

      double maxCorrection = 0.0;
      for (var entry in indexMap.entries) {
        int idx = entry.value;
        double updE = X[idx][0];
        double updN = X[idx + 1][0];
        double updH = X[idx + 2][0];

        maxCorrection = [maxCorrection, updE.abs(), updN.abs(), updH.abs()].reduce(max);

        coordMap[entry.key] = Vector.fromList([
          coordMap[entry.key]![0] + updE,
          coordMap[entry.key]![1] + updN,
          coordMap[entry.key]![2] + updH,
        ]);
      }

      iterations++;
      if (maxCorrection < 0.001) converged = true;
    }

    return _computeQCStatistics(A!, W!, L!, X!, coordMap, numObs, numParams);
  }

  void _applyJacobianRow(List<double> row, String fromId, String toId, Map<String, int> indexMap, double deCoef, double dnCoef, double dhCoef) {
    if (indexMap.containsKey(fromId)) {
      int idx = indexMap[fromId]!;
      row[idx] = -deCoef; row[idx + 1] = -dnCoef; row[idx + 2] = -dhCoef;
    }
    if (indexMap.containsKey(toId)) {
      int idx = indexMap[toId]!;
      row[idx] = deCoef; row[idx + 1] = dnCoef; row[idx + 2] = dhCoef;
    }
  }

  Vector _getCoord(String id, Map<String, Vector> coordMap) {
    if (coordMap.containsKey(id)) return coordMap[id]!;
    var ctrl = controlPoints.firstWhere((c) => c.id == id);
    return Vector.fromList([ctrl.easting, ctrl.northing, ctrl.height]);
  }

  Map<String, dynamic> _computeQCStatistics(Matrix A, Matrix W, Matrix L, Matrix X, Map<String, Vector> coords, int n, int u) {
    var V = (A * X) - L;
    var VT = V.transpose();
    var vtwv = (VT * W * V)[0][0];
    int redundancy = n - u;
    double sigma0Sq = redundancy > 0 ? vtwv / redundancy : 0.0;

    List<int> flaggedOutliers = [];
    for (int i = 0; i < V.rowCount; i++) {
      double residual = V[i][0].abs();
      double weight = W[i][i];
      double stdDev = sqrt(1.0 / weight);
      if (residual > 3 * stdDev) flaggedOutliers.add(i);
    }

    return {
      'adjustedCoordinates': coords,
      'referenceVariance': sigma0Sq,
      'redundancy': redundancy,
      'outliers': flaggedOutliers,
    };
  }
}