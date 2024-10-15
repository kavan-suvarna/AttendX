import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TMarkAttendance extends StatefulWidget {
  const TMarkAttendance({super.key});
  @override
  TMarkAttendanceState createState() => TMarkAttendanceState();
}

class TMarkAttendanceState extends State<TMarkAttendance> {
  String? selectedClass;
  String? selectedSubject;
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  Map<String, bool> attendanceMap =
      {}; // Map of student ID to attendance (true: present, false: absent)
  bool isSaving = false;
  bool isButtonDisabled = false; // Flag to keep track of button state

  // Class and subject mapping
  Map<String, List<String>> classSubjects = {
    "TyBscCS": [
      "Artificial Intelligence",
      "Cyber Forensics",
      "Information & Network Security",
      "Project Management",
      "Software Testing & Quality Assurance",
      "AI_Practical",
      "CF_Practical",
      "INS_Practical",
      "STQA_Practical"
    ],
    'SyBscCS': ['OS', 'LA', 'DS', 'ADBMS', 'JAVA', 'WEB', 'GT'],
  };

  @override
  void initState() {
    super.initState();
    _checkButtonState(); // Check if attendance has already been marked
  }

  // Function to check the saved button state
  Future<void> _checkButtonState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? savedState = prefs.getBool('isButtonDisabled');
    setState(() {
      isButtonDisabled = savedState ?? false; // Default is false if no state saved
    });
  }

  // Function to save the button state
  Future<void> _saveButtonState(bool state) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isButtonDisabled', state);
  }


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
            // Class dropdown
            DropdownButtonFormField<String>(
              value: selectedClass,
              hint: Text('Select Class'),
              onChanged: (newValue) {
                setState(() {
                  selectedClass = newValue;
                  selectedSubject = null; // Reset subject when class changes
                  isButtonDisabled = false; // Reset the button state
                  _saveButtonState(false); // Reset the saved state
                });
              },
              items: classSubjects.keys.map((classItem) {
                return DropdownMenuItem(
                  value: classItem,
                  child: Text(classItem),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // Subject dropdown (depends on selected class)
            DropdownButtonFormField<String>(
              value: selectedSubject,
              hint: Text('Select Subject'),
              onChanged: (newValue) {
                setState(() {
                  selectedSubject = newValue;
                  isButtonDisabled = false; // Reset the button state
                  _saveButtonState(false); // Reset the saved state
                });
              },
              items: selectedClass != null
                  ? classSubjects[selectedClass]!.map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList()
                  : [],
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
                    isButtonDisabled = false; // Reset the button state
                    _saveButtonState(false); // Reset the saved state
                  });
                }
              },
              child: Text(selectedDate == null
                  ? 'Select Date'
                  : DateFormat('yyyy-MM-dd').format(selectedDate!)),
            ),

            // Time Picker for start and end times
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? pickedStartTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedStartTime != null) {
                      setState(() {
                        startTime = pickedStartTime;
                      });
                    }
                  },
                  child: Text(startTime == null
                      ? 'Select Start Time'
                      : 'Start: ${startTime!.format(context)}'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? pickedEndTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedEndTime != null) {
                      setState(() {
                        endTime = pickedEndTime;
                      });
                    }
                  },
                  child: Text(endTime == null
                      ? 'Select End Time'
                      : 'End: ${endTime!.format(context)}'),
                ),
              ],
            ),

            SizedBox(height: 20),
            Text('CLICK CHECKBOX IF PRESENT'),
            SizedBox(height: 20),

            // List of students
            selectedClass != null &&
                    selectedSubject != null &&
                    selectedDate != null
                ? Expanded(child: _buildStudentList())
                : Container(),

            // Save Attendance Button
            ElevatedButton(
              onPressed:isButtonDisabled || isSaving // Disable the button if attendance already marked
                  ? null
                  :  () {
                if (selectedClass != null &&
                    selectedSubject != null &&
                    selectedDate != null &&
                    startTime != null &&
                    endTime != null) {
                  _saveAttendance();
                }
              },
               child: Text(isButtonDisabled
                  ? 'Attendance Already Marked'
                  : isSaving
                      ? 'Saving...'
                      : 'Save Attendance'),
            ),
          ],
        ),
      ),
    );
  }

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

                // Initialize absent students as false if not already set
                if (!attendanceMap.containsKey(studentId)) {
                  attendanceMap[studentId] = false; // Set absent by default
                }

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

  // Function to calculate duration in hours
  double _calculateLectureDuration() {
    final start = DateTime(0, 0, 0, startTime!.hour, startTime!.minute);
    final end = DateTime(0, 0, 0, endTime!.hour, endTime!.minute);
    return end.difference(start).inMinutes / 60.0;
  }

// Save attendance to Firestore
  Future<void> _saveAttendance() async {
     setState(() {
      isSaving = true;
    });
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    double lectureDuration = _calculateLectureDuration();
    String formattedStartTime = startTime!.format(context);
    String formattedEndTime = endTime!.format(context);

    for (var entry in attendanceMap.entries) {
      String studentId = entry.key;
      bool isPresent = entry.value;

      CollectionReference attendanceCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .collection('attendance');

      DocumentReference attendanceDoc =
          attendanceCollection.doc(selectedSubject);

      try {
        // Fetch the existing attendance document
        DocumentSnapshot attendanceSnapshot = await attendanceDoc.get();

        // Initialize data holders
        double currentPresentHours = 0;
        double currentTotalHours = 0;
        Map<String, dynamic> detailedAttendance = {};

        if (attendanceSnapshot.exists) {
          // Retrieve existing data if available
          Map<String, dynamic> existingAttendanceData =
              attendanceSnapshot.data() as Map<String, dynamic>;

          currentPresentHours = existingAttendanceData['presentHours'] ?? 0;
          currentTotalHours = existingAttendanceData['totalHours'] ?? 0;
          detailedAttendance =
              existingAttendanceData['detailedAttendance'] ?? {};
        }

        // Update the detailedAttendance map for the current date for both present and absent students
        detailedAttendance[formattedDate] = {
          'status': isPresent ? 'present' : 'absent',
          'startTime': formattedStartTime,
          'endTime': formattedEndTime,
        };

        // Always update total hours since the lecture was held for all students
        currentTotalHours += lectureDuration;

        // Update present hours only if the student was marked present
        if (isPresent) {
          currentPresentHours += lectureDuration;
        }

        // Calculate the updated attendance percentage
        double attendancePercentage = (currentTotalHours > 0)
            ? (currentPresentHours / currentTotalHours) * 100
            : 0;

        // Use set with merge: true to avoid overwriting existing data
        await attendanceDoc.set({
          'detailedAttendance': detailedAttendance,
          'totalHours': currentTotalHours,
          'presentHours': currentPresentHours,
          'attendancePercentage': attendancePercentage,
          'subjectName': selectedSubject,
        }, SetOptions(merge: true));

        setState(() {
          isSaving = false;
          isButtonDisabled = true; // Disable the button after saving attendance
        });

        // Save the button state to persist across sessions
        _saveButtonState(true);
      } catch (e) {
        // Handle potential errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save attendance: $e')),
          );
        }
         setState(() {
          isSaving = false;
        });
      }
    }
  }
}
