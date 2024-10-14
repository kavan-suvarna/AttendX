import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TMarkAttendance extends StatefulWidget {
  const TMarkAttendance({super.key});
  @override
  TMarkAttendanceState createState() => TMarkAttendanceState();
}

class TMarkAttendanceState extends State<TMarkAttendance> {
  String? selectedClass;
  String? selectedSubject;
  DateTime? selectedDate;
  Map<String, bool> attendanceMap =
      {}; // Map of student ID to attendance (true: present, false: absent)

  List<String> classes = ['TyBscCS', 'SyBscCS', 'FyBscCS']; // Add class options
  List<String> subjects = [
    "Artificial Intelligence",
    "Cyber Forensics",
    "Information & Network Security",
    "Project Management",
    "Software Testing & Quality Assurance",
    "AI_Practical",
    "CF_Practical",
    "INS_Practical",
    "STQA_Practical"
  ]; // Subject options

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //class dropdown
            DropdownButtonFormField<String>(
              value: selectedClass,
              hint: Text('Select Class'),
              onChanged: (newValue) {
                setState(() {
                  selectedClass = newValue;
                });
              },
              items: classes.map((classItem) {
                return DropdownMenuItem(
                  value: classItem,
                  child: Text(classItem),
                );
              }).toList(),
            ),
            SizedBox(
              height: 20,
            ),
            // Subject Dropdown
            DropdownButtonFormField<String>(
              value: selectedSubject,
              hint: Text('Select Subject'),
              onChanged: (newValue) {
                setState(() {
                  selectedSubject = newValue;
                });
              },
              items: subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
            ),

            SizedBox(height: 20),
            // Date Picker
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: Text(selectedDate == null
                  ? 'Select Date'
                  : DateFormat('yyyy-MM-dd').format(selectedDate!)),
            ),

            SizedBox(height: 20),

            // List of Students
            selectedClass != null &&
                    selectedSubject != null &&
                    selectedDate != null
                ? Expanded(child: _buildStudentList())
                : Container(),

            // Save Attendance Button
            ElevatedButton(
              onPressed: () {
                if (selectedClass != null &&
                    selectedSubject != null &&
                    selectedDate != null) {
                  _saveAttendance();
                }
              },
              child: Text('Save Attendance'),
            ),
          ],
        ),
      ),
    );
  }

  // Fetch and display students based on selected class and role
  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('class', isEqualTo: selectedClass)
            .where('role', isEqualTo: 'Student')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          var students = snapshot.data!.docs;

          return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                var student = students[index];
                String studentName = student['name'];
                String studentId = student.id;

                return ListTile(
                  title: Text(studentName),
                  trailing: Checkbox(
                      value: attendanceMap[studentId] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          attendanceMap[studentId] = value!;
                        });
                      }),
                );
              });
        });
  }

  // Save attendance to Firestore
  Future<void> _saveAttendance() async {
  String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

  for (var entry in attendanceMap.entries) {
    String studentId = entry.key;
    bool isPresent = entry.value;

    // Reference to the attendance subcollection for the student
    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .collection('attendance');

    // Check if an attendance document for the selected subject and date exists
    DocumentReference attendanceDoc = attendanceCollection.doc(selectedSubject);

    // Fetch the attendance document if it exists
    DocumentSnapshot attendanceSnapshot = await attendanceDoc.get();

    if (attendanceSnapshot.exists) {
      // Update the existing attendance record
      Map<String, dynamic> existingAttendanceData = attendanceSnapshot.data() as Map<String, dynamic>;

      existingAttendanceData['detailedAttendance'][formattedDate] =
          isPresent ? 'present' : 'absent';

      await attendanceDoc.update({
        'detailedAttendance': existingAttendanceData['detailedAttendance'],
      });
    } else {
      // Create a new attendance document for the subject
      await attendanceDoc.set({
        'attendancePercentage': 0,
        'presentHours': 0,
        'totalHours': 0,
        'subjectName': selectedSubject,
        'detailedAttendance': {
          formattedDate: isPresent ? 'present' : 'absent',
        },
      });
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Attendance saved successfully!'),
  ));
}

}
