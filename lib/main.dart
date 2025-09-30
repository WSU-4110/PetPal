import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
//import 'ui/home_screen.dart';
import 'ui/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init(); // init DB
  runApp(PetPalApp(appState: appState));
}

class PetPalApp extends StatelessWidget {
  final AppState appState;
  const PetPalApp({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        title: 'PetPal',
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        home: const LoginPage(),
      ),
    );
  }
}
