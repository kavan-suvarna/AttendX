import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class AProfilePage extends StatefulWidget {
  const AProfilePage({super.key});
  @override
  AProfilePageState createState() => AProfilePageState();
}

class AProfilePageState extends State<AProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? adminData;

  @override
  void initState() {
    super.initState();
    fetchteacherData();
  }

  void fetchteacherData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        adminData = doc.data() as Map<String, dynamic>?;
      });
    }
  }

  // Function to log out the user
  void logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  LoginPage())); // Navigate to login screen after logout
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Profile"),
        backgroundColor: Colors.deepPurple[100],
        centerTitle: true,
        elevation: 0,
      ),
      body: adminData != null
          ? buildProfilePage()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget buildProfilePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture Placeholder with Rounded Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.deepPurple[100],
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            SizedBox(height: 20),

            // Card containing user info
            Card(
              elevation: 5,
              shadowColor: Colors.deepPurple[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildProfileItem('Name', adminData!['name']),
                    buildProfileItem('Email', adminData!['email']),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Logout Button with elevated design
            ElevatedButton(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // background color
                foregroundColor: Colors.white, // Button text color
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(30), // Rounded button corners
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shadowColor: Colors.black,
                elevation: 10,
              ),
              child: Text('Logout', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for individual profile items
  Widget buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.indigo,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  ManageUsersState createState() => ManageUsersState();
}

class ManageUsersState extends State<ManageUsers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

  List<DocumentSnapshot> userList = [];
  bool isLoading = true;
  String selectedClass = 'All';
  String selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    Query query = _firestore.collection('users');

    if (selectedClass != 'All') {
      query = query.where('class', isEqualTo: selectedClass);
    }

    if (selectedRole != 'All') {
      query = query.where('role', isEqualTo: selectedRole);
    }

    QuerySnapshot querySnapshot = await query.get();
    setState(() {
      userList = querySnapshot.docs;
      isLoading = false;
    });
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User removed successfully')),
        );
      }

      // Refresh user list
      fetchUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
      ),
      body: Column(
        children: [
          // Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<String>(
                value: selectedClass,
                items:
                    <String>['All', 'TyBscCS', 'SyBscCS'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedClass = newValue!;
                    fetchUsers();
                  });
                },
              ),
              DropdownButton<String>(
                value: selectedRole,
                items:
                    <String>['All', 'Student', 'Teacher'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedRole = newValue!;
                    fetchUsers();
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: userList.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot userDoc = userList[index];
                      String name = userDoc['name'];
                      String email = userDoc['email'];
                      String role = userDoc['role'];
                      String userId = userDoc.id;

                      return ListTile(
                        title: Text('$name ($role)'),
                        subtitle: Text(email),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteUser(userId),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ViewUsersScreen extends StatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  _ViewUsersScreenState createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends State<ViewUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Users'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore.collection('users').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No users found'));
          }

          List<DocumentSnapshot> users = snapshot.data!.docs;

          users.sort((a, b) {
            String roleA = (a['role'] as String?)?.toLowerCase() ?? 'student';
            String roleB = (b['role'] as String?)?.toLowerCase() ?? 'student';

            if (roleA == roleB) return 0;
            if (roleA == 'admin') return -1;
            if (roleA == 'teacher' && roleB != 'admin') return -1;
            return 1;
          });

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              String role = user['role']?.toLowerCase() ?? 'student';

              return ListTile(
                leading: Icon(
                  role == 'admin'
                      ? Icons.admin_panel_settings
                      : role == 'teacher'
                          ? Icons.school
                          : Icons.person,
                  color: role == 'admin'
                      ? Colors.red
                      : role == 'teacher'
                          ? Colors.blue
                          : Colors.green,
                ),
                title: Text(user['name'] ?? 'No name'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${user['email'] ?? 'No email'}'),
                    if (role == 'student') ...[
                      Text('Class: ${user['class'] ?? 'N/A'}'),
                      Text('Roll No: ${user['rollno'] ?? 'N/A'}'),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

