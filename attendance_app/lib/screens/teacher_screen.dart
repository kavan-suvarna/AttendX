import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'teacher_markattendance_screen.dart';


class Teacherscreen extends StatelessWidget {
  const Teacherscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[100],
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TProfilePage()));
            },
            icon: const Icon(Icons.person_outline),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome, Teacher!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => TMarkAttendance()));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Mark Student Attendance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TViewStudent()));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                'View Students',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade200,
    );
  }
}

class TProfilePage extends StatefulWidget {
  const TProfilePage({super.key});
  @override
  TProfilePageState createState() => TProfilePageState();
}

class TProfilePageState extends State<TProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? teacherData;

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
        teacherData = doc.data() as Map<String, dynamic>?;
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
        title: Text("Teacher Profile"),
        backgroundColor:
            Colors.deepPurple[100], // Customize app bar background color
        centerTitle: true,
        elevation: 0,
      ),
      body: teacherData != null
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
                    buildProfileItem('Name', teacherData!['name']),
                    buildProfileItem('Email', teacherData!['email']),
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

class TViewStudent extends StatefulWidget {
  const TViewStudent({super.key});

  @override
  _TViewStudentState createState() => _TViewStudentState();
}

class _TViewStudentState extends State<TViewStudent> {
 
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Students'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('users')
            .where('role', isEqualTo: 'Student') // Only students
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No students found'));
          }

          List<DocumentSnapshot> students = snapshot.data!.docs;

          return SingleChildScrollView( 
            child: Column(
              children: [
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(), 
                  shrinkWrap: true, 
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var student = students[index];
                    String studentId = student.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ExpansionTile(
                        title: Text(student['name'] ?? 'No name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Class: ${student['class'] ?? 'N/A'}'),
                            Text('Roll No: ${student['rollno'] ?? 'N/A'}'),
                            Text('Email: ${student['email'] ?? 'N/A'}'),
                          ],
                        ),
                        children: [
                          FutureBuilder<QuerySnapshot>(
                            future: _firestore
                                .collection('users')
                                .doc(studentId)
                                .collection('attendance') 
                                .get(),
                            builder: (context, attendanceSnapshot) {
                              if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!attendanceSnapshot.hasData || attendanceSnapshot.data == null) {
                                return const Center(child: Text('No attendance data found'));
                              }

                              List<DocumentSnapshot> attendanceDocs = attendanceSnapshot.data!.docs;

                              return ListView.builder(
                                physics: const NeverScrollableScrollPhysics(), 
                                shrinkWrap: true, 
                                itemCount: attendanceDocs.length,
                                itemBuilder: (context, attendanceIndex) {
                                  var attendanceData = attendanceDocs[attendanceIndex];
                                  return ListTile(
                                    title: Text('Subject: ${attendanceData['subjectName'] ?? 'N/A'}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Attendance Percentage: ${attendanceData['attendancePercentage'] ?? 'N/A'}%'),
                                        Text('Present Hours: ${attendanceData['presentHours'] ?? 'N/A'} / ${attendanceData['totalHours'] ?? 'N/A'}'),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

