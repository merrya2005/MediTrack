import 'package:flutter/material.dart';
import 'package:patient_app/homepage.dart';
import 'package:patient_app/login.dart';
import 'package:patient_app/medicine.dart';
import 'package:patient_app/registration.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://mljbjfergagbzjlacsiy.supabase.co',
    anonKey: 'sb_publishable_XyvQpgUvxuzWDXdNTZK9AA_DSpaadGg',
  );
  runApp(MainApp());
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PatientLoginScreen());
  }
}
