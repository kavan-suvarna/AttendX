import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAttendance extends StatefulWidget {
  const ViewAttendance({super.key});
  @override
  ViewAttendanceState createState() => ViewAttendanceState();
}

class ViewAttendanceState extends State<ViewAttendance> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //this  variable will hold the data that we will fetch
  List<Map<String, dynamic>> subjects = [];
  String? uid;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData(); //calling the function, will fetch data when the widget is initialized
  }

  Future<void> fetchAttendanceData() async {
    try {
      //getting the UID
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        uid = currentUser.uid;

        //fetching the subject of a student
        QuerySnapshot subjectSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('attendance')
            .get();

        List<Map<String, dynamic>> fetchedSubjects = [];

        //iterating over fetched subjects
        for (var doc in subjectSnapshot.docs) {
        fetchedSubjects.add({
          'subjectName': doc['subjectName'] ?? 'Unknown',
          // Safely cast to double
          'attendancePercentage': (doc['attendancePercentage'] is num)
              ? (doc['attendancePercentage'] as num).toDouble()
              : 0.0,
          'totalHours': (doc['totalHours'] is num)
              ? (doc['totalHours'] as num).toDouble()
              : 0.0,
          'presentHours': (doc['presentHours'] is num)
              ? (doc['presentHours'] as num).toDouble()
              : 0.0,
        });
      }


        setState(() {
          subjects = fetchedSubjects;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No user currently logged in')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching data:$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          DropdownButton<String>(
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              items: <String>['Sem V', 'Sem VI'].map((String value) {
                return DropdownMenuItem<String>(
                    value: value, child: Text(value));
              }).toList(),
              onChanged: (_) {})
        ],
      ),
      body: subjects.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                var subject = subjects[index];
                return buildSubjectTile(
                    context,
                    subject['subjectName'] ?? 'Unknown',
                    subject['attendancePercentage']?.toDouble() ?? 0.0,
                    hasDetails: true,
                    totalHours: subject['totalHours']?.toDouble() ?? 0.0,
                    presentHours: subject['presentHours']?.toDouble() ?? 0.0);
              },
            ),
    );
  }

  Widget buildSubjectTile(
      BuildContext context, String subject, double attendance,
      {bool isLow = false,
      bool hasDetails = false,
      double? totalHours,
      double? presentHours}) {
    return Card(
      child: ListTile(
        title: Text(subject),
        trailing: CircularPercentIndicator(
          radius: 21.0,
          lineWidth: 5.0,
          percent: (attendance / 100).clamp(0.0, 1.0),
          center: Text(
            '$attendance%',
            style: TextStyle(fontSize: 10),
          ),
          progressColor: isLow ? Colors.orange : Colors.green,
        ),
        subtitle: hasDetails
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Total Hours:${totalHours ?? 0.0}\nPresent Hours:${presentHours ?? 0.0}'),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DetailedAttendance(
                                    subjectName:
                                        subject //passing the subject name dynamically
                                    )));
                      },
                      child: const Text('Detailed Attendance'))
                ],
              )
            : null,
      ),
    );
  }
}

//calendar view of the attendance
class DetailedAttendance extends StatefulWidget {
  const DetailedAttendance({super.key, required this.subjectName});
  final String subjectName; // Accept subject name from the previous screen

  @override
  DetailedAttendanceState createState() => DetailedAttendanceState();
}

class DetailedAttendanceState extends State<DetailedAttendance> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? uid;

  Map<DateTime, bool> attendanceRecords =
      {}; // Store attendance data for the calendar

  @override
  void initState() {
    super.initState();
    fetchAttendanceRecords(); // Fetch attendance records for the calendar
  }

  Future<void> fetchAttendanceRecords() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        uid = currentUser.uid;

        // Query the document where the 'subjectName' matches the provided subject
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('attendance')
            .where('subjectName',
                isEqualTo: widget.subjectName) // Matching the subject name
            .get();

        // Check if the document exists
        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot subjectDoc = querySnapshot.docs.first;

          // Fetch the attendance data
          if (subjectDoc.exists) {
            Map<String, dynamic> records = subjectDoc['detailedAttendance'];
            print('Fetched attendance records: $records');

            // Convert the records map to use DateTime as keys
            setState(() {
              attendanceRecords = records.map((key, value) =>
                  MapEntry(DateTime.parse(key), value == 'present'));
              print('Mapped attendanceRecords: $attendanceRecords');
            });
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No attendance records found')));
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No document found for this subject')));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No user currently logged in')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching attendance records: $e')));
      }
    }
  }

  // Helper function to compare only the date part, ignoring the time.
  bool isSameDayIgnoreTime(DateTime day1, DateTime day2) {
    return day1.year == day2.year &&
        day1.month == day2.month &&
        day1.day == day2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            headerStyle: HeaderStyle(formatButtonVisible: false),
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: (day) {
              // Check if there is an attendance record for this day
              return attendanceRecords.entries
                      .any((entry) => isSameDayIgnoreTime(entry.key, day))
                  ? [attendanceRecords[day] == true ? 'present' : 'absent']
                  : [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: attendanceRecords[_selectedDay] == true
                    ? Colors.green // Green dot for present
                    : Colors.red, // Red dot for absent
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: _selectedDay != null
                ? Center(
                    child: attendanceRecords.containsKey(_selectedDay)
                        ? Text(attendanceRecords[_selectedDay!] == true
                            ? 'Present on this day'
                            : 'Absent on this day')
                        : const Text('No attendance record for this day'),
                  )
                : const Center(child: Text('Select a day')),
          ),
        ],
      ),
    );
  }
}
