import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Garante a inicializacao dos bindings nativos do Flutter antes de acessar servicos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa formatacao de datas para o padrao brasileiro (pt_BR)
  await initializeDateFormatting('pt_BR', null);

  runApp(const RegistroPontoApp());
}

class RegistroPontoApp extends StatelessWidget {
  const RegistroPontoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Ponto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}
