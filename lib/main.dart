import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:webview_to_pdf/web_to_pdf.dart';
const String imageBox ='imageBox';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web page to pdf',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: WebToPdf(),
    );
  }
}
