const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const firestore = admin.firestore();

exports.addAttendanceFields = functions.firestore
    .document("users/{userId}")
    .onCreate(async (snap, context) => {
      const userData = snap.data();
      const userId = context.params.userId;

      // Check if the new user is a student and has a class field
      if (userData.role === "Student" && userData.class) {
        // Assign subjects based on the class field
        let subjects;
        switch (userData.class) {
          case "TyBscCS": // Example class
            // eslint-disable-next-line max-len
            subjects = ["Artificial Intelligence", "Cyber Forensics", "Information & Network Security", "Project Management", "Software Testing & Quality Assurance", "AI_Practical", "CF_Practical", "INS_Practical", "STQA_Practical"];
            break;
          case "SyBscCS": // You can add more cases for other classes
            // eslint-disable-next-line max-len
            subjects = ["OS", "LA", "DS", "ADBMS", "JAVA", "WEB"];
            break;
          default:
            subjects = []; // empty subject list if class unrecognized
        }

        // Create fields for each subject in 'attendance' subcollection
        const attendancePromises = subjects.map(async (subject) => {
          const attendanceData = {
            attendancePercentage: 0, // Default percentage
            presentHours: 0, // Default value
            totalHours: 0, // Default value
            subjectName: subject,
            detailedAttendance: {}, // Empty initially
          };

          // Add the attendance document for each subject
          return firestore
              .collection("users")
              .doc(userId)
              .collection("attendance")
              .doc(subject)
              .set(attendanceData);
        });

        // Wait for all the attendance documents to be created
        return Promise.all(attendancePromises);
      } else {
        return null; // If user is not a student or class wasnt added,do nothing
      }
    });
