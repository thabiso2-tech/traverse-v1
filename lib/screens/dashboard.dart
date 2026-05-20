import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Navigation State Trackers
  int _currentTabIndex = 0;
  
  // Traverse Properties State Trackers
  String _traverseType = 'Closed Loop'; // Default network type configuration
  String? _importedFileName;
  List<List<dynamic>> _csvDataMatrix = [];

  // Form Fields Controllers for Control Station initialization
  final TextEditingController _stationIdController = TextEditingController();
  final TextEditingController _eastingController = TextEditingController();
  final TextEditingController _northingController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  /// Handles opening the system storage to ingest survey raw field books (.csv)
  Future<void> _handleCSVImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String csvContent = await file.readAsString();
        
        // Simple line parser split to map out raw station logs
        List<String> lines = csvContent.split('\n');
        List<List<dynamic>> parsedRows = [];
        
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            parsedRows.add(line.split(','));
          }
        }

        setState(() {
          _importedFileName = result.files.single.name;
          _csvDataMatrix = parsedRows;
          // Jump user over to raw data logging screen to confirm parsed entries
          _currentTabIndex = 1; 
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully loaded: $_importedFileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing data layout: $e')),
      );
    }
  }

  @override
  void dispose() {
    _stationIdController.dispose();
    _eastingController.dispose();
    _northingController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107), // Golden Yellow
        elevation: 0,
        title: const Text(
          '3D TRAVERSE ADJ',
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.2,
          ),
        ),
        // Sub-Navigation Tab bar directly handles index selection
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Container(
            color: const Color(0xFFFFC107),
            child: Row(
              children: [
                _buildTabButton(index: 0, label: '1. SETUP', icon: Icons.settings),
                _buildTabButton(index: 1, label: '2. RAW DATA', icon: Icons.analytics),
                _buildTabButton(index: 2, label: '3. RESULTS', icon: Icons.assessment),
              ],
            ),
          ),
        ),
      ),
      body: _buildActivePageBody(),
    );
  }

  /// Builds a responsive selector tab widget button
  Widget _buildTabButton({required int index, required String label, required IconData icon}) {
    final bool isActive = _currentTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black,
                width: isActive ? 4.0 : 0.0, // Indicated selection bar
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black87, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Controls rendering corresponding screen spaces depending on navigation states
  Widget _buildActivePageBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildSetupView();
      case 1:
        return _buildRawDataView();
      case 2:
        return _buildResultsView();
      default:
        return _buildSetupView();
    }
  }

  // ==========================================
  // VIEW SCREEN 1: NETWORK GENERATOR & PROFILES
  // ==========================================
  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRAVERSE NETWORK ARCHITECTURE',
            style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          // Network Configuration Dropdown Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFC107)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _traverseType,
                dropdownColor: Colors.grey[900],
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: <String>['Closed Loop', 'Open Link / Connected'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).valueListizable(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _traverseType = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'CONTROL STATIONS INITIALIZATION',
            style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildStyledTextField(label: 'Station ID/Name', controller: _stationIdController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStyledTextField(label: 'Easting (m)', controller: _eastingController, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildStyledTextField(label: 'Northing (m)', controller: _northingController, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildStyledTextField(label: 'Height (m)', controller: _heightController, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 35),
          
          // Action Buttons Container
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
              onPressed: () {
                // Initialize profile action...
              },
              child: const Text('INITIALIZE PROJECT PROFILE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          
          // CSV Loader System Core Trigger
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
              ),
              onPressed: _handleCSVImport,
              icon: const Icon(Icons.file_upload, color: Color(0xFFFFC107)),
              label: Text(
                _importedFileName == null ? 'IMPORT FIELD BOOK (CSV)' : 'RELOAD: $_importedFileName',
                style: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW SCREEN 2: LOG MATRIX OBSERVATIONS
  // ==========================================
  Widget _buildRawDataView() {
    if (_csvDataMatrix.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, color: Colors.grey[700], size: 60),
            const SizedBox(height: 16),
            const Text(
              'No raw field entries loaded yet.\nImport a CSV file inside the Setup panel.',
              textAlign: Center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey[900],
          padding: const EdgeInsets.all(12),
          child: Text(
            'Mode: $_traverseType  |  File: $_importedFileName',
            style: const TextStyle(color: Color(0xFFFFC107), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: _csvDataMatrix.first.map((header) {
                  return DataColumn(
                    label: Text(
                      header.toString().toUpperCase(),
                      style: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                rows: _csvDataMatrix.skip(1).map((row) {
                  return DataRow(
                    cells: row.map((cell) {
                      return DataCell(
                        Text(cell.toString(), style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW SCREEN 3: MATH RECONCILIATION CLOSURE
  // ==========================================
  Widget _buildResultsView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outlier Validation Error Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350), // Red Warning
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.black, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'OUTLIER ALERT: Residual validation failed at Leg 2 (> 3σ Threshold limit for $_traverseType)',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ADJUSTMENT STATISTICS:',
            style: TextStyle(color: Color(0xFF4CAF50), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Target closure achieved:', '1:68,200'),
          _buildStatRow('Global Sigma-Zero Unit:', '1.023'),
          _buildStatRow('Standard Error Easting:', '±0.003m'),
          _buildStatRow('Standard Error Northing:', '±0.002m'),
          _buildStatRow('Standard Error Elevation:', '±0.005m'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
              onPressed: () {
                // Export logic code block execution
              },
              icon: const Icon(Icons.download, color: Colors.black),
              label: const Text('EXPORT RECONCILED RUN DATA (CSV)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStyledTextField({required String label, required TextEditingController controller, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFC107))),
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Quick helper extension map block to handle generic list validation conversion layout formats
extension DropdownItemsListExt<T> on Iterable<T> {
  List<T> valueListizable() => toList();
}
