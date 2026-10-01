import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/punch_model.dart';
import '../models/user_model.dart';
import '../models/workplace_model.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'workplace_config_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WorkplaceModel? _workplace;
  Position? _currentPosition;
  double? _currentDistance;
  bool _isLoadingLocation = false;
  bool _isRegisteringPunch = false;
  String _selectedPunchType = 'Entrada';
  String? _locationErrorMessage;

  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  final List<String> _punchTypes = ['Entrada', 'Intervalo', 'Retorno', 'Saída'];

  @override
  void initState() {
    super.initState();
    // Inicia relogio em tempo real atualizando a cada segundo
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  // Carrega informacoes da empresa e busca a posicao GPS inicial
  Future<void> _loadData() async {
    final workplace = await DatabaseService.instance.getWorkplace();
    if (mounted) {
      setState(() {
        _workplace = workplace;
      });
      await _checkLocation();
    }
  }

  // Obtem as coordenadas GPS atuais e calcula a distancia ate a empresa
  Future<void> _checkLocation() async {
    if (_workplace == null) return;

    setState(() {
      _isLoadingLocation = true;
      _locationErrorMessage = null;
    });

    try {
      final position = await LocationService.instance.getCurrentLocation();
      final distance = LocationService.instance.calculateDistance(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: _workplace!.latitude,
        endLongitude: _workplace!.longitude,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentDistance = distance;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationErrorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Verifica se o funcionario esta dentro do limite de 100 metros
  bool get _isInsideRadius {
    if (_currentDistance == null || _workplace == null) return false;
    return _currentDistance! <= _workplace!.radiusMeters;
  }

  // Executa o registro de ponto apos validar raio de 100m e autenticacao
  Future<void> _registerPunch({required bool useBiometric}) async {
    // 1. Garante que temos a localizacao mais atualizada
    if (_currentPosition == null || _currentDistance == null) {
      await _checkLocation();
      if (_currentPosition == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível obter sua localização GPS.')),
        );
        return;
      }
    }

    // 2. Regra obrigatoria do trabalho: Ponto somente a ate 100 metros
    if (!_isInsideRadius) {
      _showOutsideRadiusDialog();
      return;
    }

    String authType = 'Senha';

    // 3. Autenticacao Biometrica se solicitada
    if (useBiometric) {
      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Confirme sua biometria para validar o registro de ponto',
      );

      if (!authenticated) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha na validação biométrica do ponto.')),
        );
        return;
      }
      authType = 'Biometria';
    }

    setState(() => _isRegisteringPunch = true);

    try {
      // Cria o registro com data, hora, coordenadas e distancia
      final punch = PunchModel(
        userNif: widget.user.nif,
        userName: widget.user.name,
        punchType: _selectedPunchType,
        timestamp: DateTime.now(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        distanceMeters: _currentDistance!,
        isValidLocation: true,
        authenticationType: authType,
      );

      // Salva no banco de dados SQLite
      await DatabaseService.instance.insertPunch(punch);

      if (!mounted) return;
      _showSuccessPunchDialog(punch);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar ponto: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRegisteringPunch = false);
    }
  }

  // Dialogo exibido quando o usuario tenta bater ponto longe do trabalho (>100m)
  void _showOutsideRadiusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDarkBlue,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 28),
            SizedBox(width: 8),
            Text('Fora da Área Permitida', style: TextStyle(color: AppTheme.textLight, fontSize: 18)),
          ],
        ),
        content: Text(
          'Você está a ${_currentDistance?.toStringAsFixed(1) ?? "?"} metros da empresa.\n\n'
          'O registro de ponto só é permitido a até ${_workplace?.radiusMeters.toStringAsFixed(0) ?? 100} metros do local de trabalho.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: AppTheme.lightBlue)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openWorkplaceConfig();
            },
            child: const Text('Ajustar Local'),
          ),
        ],
      ),
    );
  }

  // Dialogo de confirmacao de registro bem-sucedido
  void _showSuccessPunchDialog(PunchModel punch) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDarkBlue,
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 28),
            SizedBox(width: 8),
            Text('Ponto Registrado!', style: TextStyle(color: AppTheme.textLight, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${punch.punchType}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight)),
            const SizedBox(height: 4),
            Text('Data: ${dateFormat.format(punch.timestamp)}', style: const TextStyle(color: AppTheme.textMuted)),
            Text('Hora: ${timeFormat.format(punch.timestamp)}', style: const TextStyle(color: AppTheme.textMuted)),
            Text('Autenticação: ${punch.authenticationType}', style: const TextStyle(color: AppTheme.textMuted)),
            Text('Distância: ${punch.distanceMeters.toStringAsFixed(1)} metros', style: const TextStyle(color: AppTheme.textMuted)),
            const Text('Status: Dentro do raio de 100m', style: TextStyle(color: AppTheme.successGreen)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
  }

  // Abre a tela para reconfigurar coordenadas da empresa
  Future<void> _openWorkplaceConfig() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkplaceConfigScreen()),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('HH:mm:ss');
    final dateFormatter = DateFormat('EEEE, dd/MM/yyyy', 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ponto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Histórico de Pontos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HistoryScreen(user: widget.user)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurar Empresa',
            onPressed: _openWorkplaceConfig,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cartao de Boas-vindas e Identificacao do Colaborador
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.3),
                      child: const Icon(Icons.person, color: AppTheme.lightBlue, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NIF: ${widget.user.nif} • ${widget.user.email}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cartao do Relogio Digital em Tempo Real
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      timeFormatter.format(_currentTime),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppTheme.lightBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatter.format(_currentTime).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cartao de Geolocalizacao e Raio de 100m
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: AppTheme.lightBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Localização & Raio (100m)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.lightBlue),
                                )
                              : const Icon(Icons.refresh, size: 20, color: AppTheme.lightBlue),
                          onPressed: _isLoadingLocation ? null : _checkLocation,
                          tooltip: 'Atualizar GPS',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Exibicao de erro de GPS se houver
                    if (_locationErrorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _locationErrorMessage!,
                          style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Detalhes da localizacao e calculo da distancia
                    if (_currentPosition != null && _currentDistance != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Distância da Empresa:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          Text(
                            '${_currentDistance!.toStringAsFixed(1)} metros',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Limite Permitido:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          Text(
                            '${_workplace?.radiusMeters.toStringAsFixed(0) ?? 100} metros',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Badge visual indicando se esta apto ou fora do raio
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: (_isInsideRadius ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isInsideRadius ? AppTheme.successGreen : AppTheme.errorRed,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isInsideRadius ? Icons.verified_user_rounded : Icons.cancel_rounded,
                              color: _isInsideRadius ? AppTheme.successGreen : AppTheme.errorRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isInsideRadius
                                    ? 'Localização válida: Você está dentro do raio de 100m.'
                                    : 'Atenção: Você está fora do raio de 100m da empresa.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isInsideRadius ? AppTheme.successGreen : AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cartao de Selecao do Tipo de Ponto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Registro',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _punchTypes.map((type) {
                        final isSelected = _selectedPunchType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: AppTheme.accentBlue,
                          backgroundColor: AppTheme.cardDarkBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedPunchType = type);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botao Principal: Bater Ponto com Biometria
            ElevatedButton.icon(
              onPressed: _isRegisteringPunch ? null : () => _registerPunch(useBiometric: true),
              icon: const Icon(Icons.fingerprint, size: 24),
              label: _isRegisteringPunch
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Registrar $_selectedPunchType com Biometria'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Botao Secundario: Bater Ponto com Autenticacao por Senha/Confirmacao Direta
            OutlinedButton.icon(
              onPressed: _isRegisteringPunch ? null : () => _registerPunch(useBiometric: false),
              icon: const Icon(Icons.check_circle_outline),
              label: Text('Registrar $_selectedPunchType com Senha'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textLight,
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Atalho para Historico de Pontos
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HistoryScreen(user: widget.user)),
                );
              },
              icon: const Icon(Icons.list_alt, color: AppTheme.lightBlue),
              label: const Text(
                'Ver Histórico Completo de Pontos',
                style: TextStyle(color: AppTheme.lightBlue, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
