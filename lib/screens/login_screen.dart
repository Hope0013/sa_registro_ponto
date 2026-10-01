import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Faz login tradicional usando NIF ou E-mail e senha
  Future<void> _handlePasswordLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o NIF/E-mail e a senha.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DatabaseService.instance.login(identifier, password);

      if (!mounted) return;

      if (user != null) {
        // Redireciona para a tela principal enviando o usuario logado
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciais incorretas ou usuário não encontrado.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao realizar login: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Realiza a autenticacao via biometria (digital ou reconhecimento facial)
  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);

    try {
      final isAvailable = await BiometricService.instance.isBiometricAvailable();

      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sensor biométrico não disponível ou não configurado no aparelho.')),
        );
        return;
      }

      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Utilize sua digital ou reconhecimento facial para entrar',
      );

      if (!mounted) return;

      if (authenticated) {
        // Se o usuario digitou um NIF/Email, buscamos ele. Caso contrario, usamos o primeiro usuario cadastrado
        UserModel? user;
        final identifier = _identifierController.text.trim();

        if (identifier.isNotEmpty) {
          user = await DatabaseService.instance.getUserByIdentifier(identifier);
        } else {
          user = await DatabaseService.instance.getFirstUser();
        }

        if (!mounted) return;

        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(user: user!)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum usuário cadastrado no sistema para vincular à biometria.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha na autenticação biométrica: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Preenche automaticamente as credenciais de teste para ajudar o professor
  void _fillTestCredentials() {
    setState(() {
      _identifierController.text = '123456';
      _passwordController.text = '123456';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icone e Titulo do Aplicativo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDarkBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.lightBlue.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    size: 56,
                    color: AppTheme.lightBlue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Registro de Ponto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Autenticação com Geolocalização e Biometria',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 36),

                // Campo NIF ou E-mail
                TextField(
                  controller: _identifierController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'NIF ou E-mail',
                    hintText: 'Ex: 123456 ou carlos@empresa.com',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de Senha
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botao de Login com Senha
                ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Entrar com Senha'),
                ),
                const SizedBox(height: 14),

                // Botao de Login com Biometria
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleBiometricLogin,
                  icon: const Icon(Icons.fingerprint, size: 24),
                  label: const Text('Entrar com Biometria / Facial'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.lightBlue,
                    side: const BorderSide(color: AppTheme.lightBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Atalho com credenciais de teste para o professor
                TextButton.icon(
                  onPressed: _fillTestCredentials,
                  icon: const Icon(Icons.help_outline, size: 18, color: AppTheme.textMuted),
                  label: const Text(
                    'Preencher credenciais de teste (NIF: 123456)',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),

                // Link para Cadastro de Novo Usuario
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Não possui conta?',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Cadastre-se',
                        style: TextStyle(color: AppTheme.lightBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
