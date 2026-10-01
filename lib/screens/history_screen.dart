import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/punch_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final UserModel user;

  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PunchModel> _punches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Busca do SQLite o historico de pontos do usuario
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseService.instance.getPunchesByUser(widget.user.nif);
      setState(() {
        _punches = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Retorna icone de acordo com o tipo de batida de ponto
  IconData _getPunchIcon(String type) {
    switch (type.toLowerCase()) {
      case 'entrada':
        return Icons.login_rounded;
      case 'intervalo':
        return Icons.coffee_rounded;
      case 'retorno':
        return Icons.work_history_rounded;
      case 'saída':
      case 'saida':
        return Icons.logout_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Pontos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _punches.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: AppTheme.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum ponto registrado ainda',
                          style: TextStyle(fontSize: 18, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Os registros de ponto feitos na tela inicial aparecerão aqui.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _punches.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final punch = _punches[index];
                      final dateFormat = DateFormat('dd/MM/yyyy');
                      final timeFormat = DateFormat('HH:mm:ss');

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabecalho do cartao com tipo de ponto e horario
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentBlue.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getPunchIcon(punch.punchType),
                                      color: AppTheme.lightBlue,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          punch.punchType,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                        Text(
                                          dateFormat.format(punch.timestamp),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    timeFormat.format(punch.timestamp),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.lightBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: Color(0xFF334155)),

                              // Detalhes da autenticacao e localizacao
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Metodo de autenticacao
                                  Row(
                                    children: [
                                      Icon(
                                        punch.authenticationType == 'Biometria'
                                            ? Icons.fingerprint
                                            : Icons.password,
                                        size: 16,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        punch.authenticationType,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),

                                  // Status de distancia e raio
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (punch.isValidLocation ? AppTheme.successGreen : AppTheme.errorRed)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: punch.isValidLocation ? AppTheme.successGreen : AppTheme.errorRed,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          punch.isValidLocation ? Icons.check_circle : Icons.warning_rounded,
                                          size: 14,
                                          color: punch.isValidLocation ? AppTheme.successGreen : AppTheme.errorRed,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          punch.isValidLocation
                                              ? '${punch.distanceMeters.toStringAsFixed(1)}m (Válido)'
                                              : '${punch.distanceMeters.toStringAsFixed(1)}m (Fora)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: punch.isValidLocation ? AppTheme.successGreen : AppTheme.errorRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Coordenadas gravadas
                              Text(
                                'GPS: Lat ${punch.latitude.toStringAsFixed(5)}, Lng ${punch.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
