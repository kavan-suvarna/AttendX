import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Studentscreen extends StatelessWidget {
  const Studentscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard'), actions: [
        IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
            icon: const Icon(Icons.person))
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MarkAttendance()));
                },
                child: const Text('Mark Attendance')),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ViewAttendance()));
                },
                child: const Text('View Attendance'))
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: Kavan Suvarna', style: TextStyle(fontSize: 16)),
            SizedBox(height: 15),
            Text('Roll Number:CS-7146', style: TextStyle(fontSize: 16)),
            SizedBox(height: 15),
            Text('Email:kavansuvarna56@gmail.com',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 15),
            Text('Class:TyBscCS', style: TextStyle(fontSize: 16))
          ],
        ),
      ),
    );
  }
}

class MarkAttendance extends StatelessWidget {
  const MarkAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Mark your attendance here'),
          const SizedBox(height: 30),
          ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    (const SnackBar(content: Text('Attendance Marked'))));
              },
              child: const Text('Mark Attendance!'))
        ],
      )),
    );
  }
}

class ViewAttendance extends StatefulWidget {
  const ViewAttendance({super.key});

  @override
  ViewAttendanceState createState() => ViewAttendanceState();
}

class ViewAttendanceState extends State<ViewAttendance> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2024, 5, 1),
          lastDay: DateTime.utc(2025, 5, 1),
          /*This property defines a predicate function that determines whether a given day is selected or not.
            The day parameter represents the current day being evaluated.
            The function returns true if the day is the same as the currently selected day (_selectedDay), indicating that it should be highlighted in the calendar.*/
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
            /*This function from the date_utils package checks if two DateTime objects represent the same day, ignoring the time component.
              It returns true if the days are the same, and false otherwise.*/
          },
          /*This property defines a callback function that is called when a day is selected on the calendar.
            The selectedDay parameter represents the day that was selected.
            The focusedDay parameter represents the day that is currently focused in the calendar.
            Inside the callback function, you can update the state of your widget to reflect the new selection.*/
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
          ),
        ),
      ),
    );
  }
}
