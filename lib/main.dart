// import 'package:flutter/material.dart';

// /// EUEE Prep entry point.
// ///
// /// Deliberately minimal at this stage (Milestone 0, Task 4 — project
// /// skeleton only). Riverpod's ProviderScope and real routing are added in
// /// Task 6 (routing and state management scaffolding), not here — see
// /// 10_IMPLEMENTATION_ROADMAP.md.
// void main() {
//   runApp(const EueePrepApp());
// }

// class EueePrepApp extends StatelessWidget {
//   const EueePrepApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       title: 'EUEE Prep',
//       home: Scaffold(
//         body: Center(
//           child: Text('EUEE Prep — project skeleton'),
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'features/entitlements/presentation/payment_history_screen.dart';

// void main() {
//   runApp(const MaterialApp(
//     home: PaymentHistoryScreen(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

import 'package:flutter/material.dart';
import 'features/subjects/presentation/subject_list_screen.dart';

void main() {
  runApp(const MaterialApp(
    home: SubjectListScreen(),
    debugShowCheckedModeBanner: false,
  ));
}