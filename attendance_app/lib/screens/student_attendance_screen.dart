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
  final String subjectName;
  const DetailedAttendance({super.key, required this.subjectName});

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
    fetchAttendanceRecords();
  }

  Future<void> fetchAttendanceRecords() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        uid = currentUser.uid;

        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('attendance')
            .where('subjectName', isEqualTo: widget.subjectName)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot subjectDoc = querySnapshot.docs.first;

          if (subjectDoc.exists) {
            Map<String, dynamic> records = subjectDoc['detailedAttendance'];

            setState(() {
              attendanceRecords = records.map((key, value) {
                DateTime dateKey =
                    DateTime.parse(key).toLocal(); 

                String? status = value['status'];

                bool isPresent = status == 'present';

                return MapEntry(
                  DateTime(dateKey.year, dateKey.month,
                      dateKey.day), // Use only year, month, and day
                  isPresent,
                );
              });
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No user currently logged in')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching attendance records: $e')));
      }
    }
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
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: (day) {
              DateTime eventDay = DateTime(day.year, day.month, day.day);
              if (attendanceRecords.containsKey(eventDay)) {
                return [attendanceRecords[eventDay]! ? 'Present' : 'Absent'];
              }
              return [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  if (events.first == 'Present') {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      width: 8,
                      height: 8,
                    );
                  } else if (events.first == 'Absent') {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      width: 8,
                      height: 8,
                    );
                  }
                }
                return null;
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: _selectedDay != null
                ? Center(
                    child: attendanceRecords.containsKey(DateTime(
                            _selectedDay!.year,
                            _selectedDay!.month,
                            _selectedDay!.day))
                        ? Text(attendanceRecords[DateTime(_selectedDay!.year,
                                    _selectedDay!.month, _selectedDay!.day)] ==
                                true
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
