import 'package:flutter/material.dart';

class TraverseDashboard extends StatefulWidget {
  const TraverseDashboard({super.key});

  @override
  State<TraverseDashboard> createState() => _TraverseDashboardState();
}

class _TraverseDashboardState extends State<TraverseDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D TRAVERSE ADJ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.black, letterSpacing: 1.2)),
        backgroundColor: Colors.amber,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          indicatorWeight: 4.0,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: "1. SETUP"),
            Tab(icon: Icon(Icons.add_chart), text: "2. RAW DATA"),
            Tab(icon: Icon(Icons.analytics), text: "3. RESULTS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSetupScreen(),
          _buildDataEntryScreen(),
          _buildResultsScreen(),
        ],
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text("CONTROL STATIONS", style: TextStyle(fontSize: 20, color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Station ID/Name',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Easting (m)', labelStyle: TextStyle(color: Colors.white70)))),
              SizedBox(width: 10),
              Expanded(child: TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Northing (m)', labelStyle: TextStyle(color: Colors.white70)))),
              SizedBox(width: 10),
              Expanded(child: TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Height (m)', labelStyle: TextStyle(color: Colors.white70)))),
            ],
          ),
          const SizedBox(height: 35),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.all(18)),
            onPressed: () {},
            child: const Text("INITIALIZE PROJECT PROFILE", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildDataEntryScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[900]),
            columns: const [
              DataColumn(label: Text('FROM', style: TextStyle(color: Colors.amber))),
              DataColumn(label: Text('TO', style: TextStyle(color: Colors.amber))),
              DataColumn(label: Text('HA (DMS)', style: TextStyle(color: Colors.amber))),
              DataColumn(label: Text('VA (DMS)', style: TextStyle(color: Colors.amber))),
              DataColumn(label: Text('SD (m)', style: TextStyle(color: Colors.amber))),
            ],
            rows: const [
              DataRow(cells: [
                DataCell(Text('STN01', style: TextStyle(color: Colors.white))),
                DataCell(Text('STN02', style: TextStyle(color: Colors.white))),
                DataCell(Text('124°15\'32"', style: TextStyle(color: Colors.white))),
                DataCell(Text('92°04\'11"', style: TextStyle(color: Colors.white))),
                DataCell(Text('341.512', style: TextStyle(color: Colors.white))),
              ])
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.redAccent,
            padding: const EdgeInsets.all(14),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.black),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "OUTLIER ALERT: Residual validation failed at Leg 2 (> 3σ Threshold limit)",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.black, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Container(
              color: const Color(0xFF151515),
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                "ADJUSTMENT STATISTICS:\n\n"
                "• Target closure achieved: 1:68,200\n"
                "• Global Sigma-Zero Unit: 1.023\n"
                "• Standard Error Easting: ±0.003m\n"
                "• Standard Error Northing: ±0.002m\n"
                "• Standard Error Elevation: ±0.005m",
                style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontFamily: 'monospace', height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            icon: const Icon(Icons.download, color: Colors.black),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.all(16)),
            onPressed: () {},
            label: const Text("EXPORT RECONCILED RUN DATA (CSV)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}