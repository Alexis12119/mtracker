import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Set background color to white
      ),
      home: const TrackerPage(),
    );
  }
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  TrackerPageState createState() => TrackerPageState();
}

class TrackerPageState extends State<TrackerPage> {
  bool showingGroups = true;
  String currentGroup = '';

  List<String> groups = [];
  Map<String, List<String>> territories = {};

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data when the app starts
  }

  // Load data from shared preferences
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load groups
    setState(() {
      groups = prefs.getStringList('groups') ?? [];
    });

    // Load territories
    Map<String, List<String>> loadedTerritories = {};
    for (String group in groups) {
      loadedTerritories[group] = prefs.getStringList(group) ?? [];
    }

    setState(() {
      territories =
          loadedTerritories; // Update the state with loaded territories
    });
  }

  // Save data to shared preferences
// Save data to shared preferences
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('groups', groups);
    for (String group in groups) {
      await prefs.setStringList(group, territories[group] ?? []);
    }
  }

  // Adds a new group with a number entered via dialog
  void _addGroup() async {
    String? groupNumber = await _showNumberInputDialog('Enter Group Number');
    if (groupNumber != null && groupNumber.isNotEmpty) {
      setState(() {
        groups.add(groupNumber);
        territories[groupNumber] = [];
      });
      await _saveData(); // Save changes to local storage
    }
  }

  // Adds a new territory with a name entered via dialog
  void _addTerritory() async {
    String? territoryName = await _showNameInputDialog('Enter Territory Name');
    if (territoryName != null && territoryName.isNotEmpty) {
      setState(() {
        territories[currentGroup]?.add(territoryName);
      });
      await _saveData(); // Save changes to local storage
    }
  }

  // Deletes a group and its territories
  void _deleteGroup(String group) async {
    bool confirmDelete = await _showConfirmationDialog(
        'Delete Group', 'Are you sure you want to delete group $group?');
    if (confirmDelete) {
      setState(() {
        territories.remove(group);
        groups.remove(group);
      });
      await _saveData(); // Save changes to local storage
    }
  }

  // Deletes a territory
  void _deleteTerritory(String territory) async {
    bool confirmDelete = await _showConfirmationDialog('Delete Territory',
        'Are you sure you want to delete territory $territory?');
    if (confirmDelete) {
      setState(() {
        territories[currentGroup]?.remove(territory);
      });
      await _saveData(); // Save changes to local storage
    }
  }

  // Switches to the Territory screen for the selected group
  void _showTerritories(String group) {
    setState(() {
      currentGroup = group;
      showingGroups = false;
    });
  }

  // Opens the details page for a territory with three tabs (Map, Saved, Combination)
  void _openTerritoryDetails(String territory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TerritoryDetailPage(
          territory: territory,
          onDelete: _deleteTerritory, // Pass delete function
        ),
      ),
    );
  }

  // Switch back to the Group screen
  void _backToGroups() {
    setState(() {
      showingGroups = true;
    });
  }

  // Show dialog for inputting group/territory number
  Future<String?> _showNumberInputDialog(String title) async {
    TextEditingController textController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: "Enter number here"),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close dialog without returning anything
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(textController.text); // Return input text
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog for inputting territory name
  Future<String?> _showNameInputDialog(String title) async {
    TextEditingController textController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: "Enter name here"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close dialog without returning anything
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(textController.text); // Return input text
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog
  Future<bool> _showConfirmationDialog(String title, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false); // Ensure a boolean is returned
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            showingGroups ? 'Groups' : 'Territories of Group $currentGroup'),
        leading: showingGroups
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToGroups,
              ),
      ),
      body: showingGroups ? _buildGroupGrid() : _buildTerritoryGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: showingGroups ? _addGroup : _addTerritory,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Builds the grid for groups
  Widget _buildGroupGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: groups.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => _showTerritories(groups[i]),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF41117A), // Use hex color for containers
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                groups[i],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteGroup(groups[i]); // Delete the group
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the grid for territories
  Widget _buildTerritoryGrid() {
    List<String> currentTerritories = territories[currentGroup] ?? [];
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: currentTerritories.length,
      itemBuilder: (ctx, i) => Stack(
        children: [
          GestureDetector(
            onTap: () => _openTerritoryDetails(currentTerritories[i]),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF41117A), // Use hex color for containers
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                currentTerritories[i],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteTerritory(
                      currentTerritories[i]); // Delete the territory
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TerritoryDetailPage extends StatefulWidget {
  final String territory;
  final Function(String) onDelete;

  const TerritoryDetailPage(
      {super.key, required this.territory, required this.onDelete});

  @override
  TerritoryDetailPageState createState() => TerritoryDetailPageState();
}

class TerritoryDetailPageState extends State<TerritoryDetailPage> {
  bool isTracking = false;
  List<String> savedTrails = [
    'Trail 1',
    'Trail 2',
    'Trail 3'
  ]; // State variable for saved trails

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Details of ${widget.territory}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Map'),
              Tab(text: 'Saved'),
              Tab(text: 'Combination'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMapTab(), // Map Tab
            _buildSavedTab(), // Saved Tab
            _buildCombinationTab(), // Combination Tab
          ],
        ),
      ),
    );
  }

  // Tab 1: Map Tab with start/stop tracking (dummy UI)
  Widget _buildMapTab() {
    return Center(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFF41117A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Map for ${widget.territory}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isTracking = !isTracking; // Toggle tracking state
                });
              },
              child: Text(isTracking ? 'Stop Tracking' : 'Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 2: Saved Tab showing saved trails (dynamic list)
  Widget _buildSavedTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: savedTrails.length,
      itemBuilder: (ctx, i) => Stack(
        children: [
          GestureDetector(
            onTap: () => _openSavedTrailDetail(savedTrails[i]),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF41117A),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                savedTrails[i],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteSavedTrail(savedTrails[i]); // Delete the saved trail
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Deletes a saved trail
  void _deleteSavedTrail(String trail) async {
    bool confirmDelete = await _showConfirmationDialog(
        'Delete Trail', 'Are you sure you want to delete $trail?');
    if (confirmDelete) {
      setState(() {
        savedTrails.remove(trail); // Remove the trail from the state variable
      });
    }
  }

  // Opens the detail page for a specific saved trail
  void _openSavedTrailDetail(String trail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedTrailDetailPage(trail: trail),
      ),
    );
  }

  // Tab 3: Combination Tab showing combined map view (dummy UI)
  Widget _buildCombinationTab() {
    return Center(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFF41117A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Combined Map View for Saved Trails',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog
  Future<bool> _showConfirmationDialog(String title, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false); // Ensure a boolean is returned
  }
}

// Detail page for a specific saved trail
class SavedTrailDetailPage extends StatelessWidget {
  final String trail;

  const SavedTrailDetailPage({super.key, required this.trail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Trail: $trail'),
      ),
      body: Center(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF41117A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Map for $trail',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
