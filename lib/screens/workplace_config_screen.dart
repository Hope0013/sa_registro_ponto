import 'package:flutter/material.dart';
import '../models/workplace_model.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class WorkplaceConfigScreen extends StatefulWidget {
  const WorkplaceConfigScreen({super.key});

  @override
  State<WorkplaceConfigScreen> createState() => _WorkplaceConfigScreenState();
}

class _WorkplaceConfigScreenState extends State<WorkplaceConfigScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  WorkplaceModel? _workplace;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWorkplace();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  // Carrega as coordenadas atuais da empresa salvas no SQLite
  Future<void> _loadWorkplace() async {
    try {
      final workplace = await DatabaseService.instance.getWorkplace();
      setState(() {
        _workplace = workplace;
        _nameController.text = workplace.name;
        _latController.text = workplace.latitude.toString();
        _lngController.text = workplace.longitude.toString();
        _radiusController.text = workplace.radiusMeters.toStringAsFixed(0);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Captura a localizacao atual do celular e preenche nos campos para facilitar o teste do professor
  Future<void> _useCurrentLocation() async {
    setState(() => _isSaving = true);
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      setState(() {
        _latController.text = pos.latitude.toString();
        _lngController.text = pos.longitude.toString();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua localização atual foi preenchida! Clique em Salvar.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter GPS: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Salva os novos parametros de local de trabalho
  Future<void> _saveConfig() async {
    final name = _nameController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final radius = double.tryParse(_radiusController.text.trim()) ?? 100.0;

    if (name.isEmpty || lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe valores válidos de latitude e longitude.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = WorkplaceModel(
        id: _workplace?.id ?? 1,
        name: name,
        latitude: lat,
        longitude: lng,
        radiusMeters: radius,
      );

      await DatabaseService.instance.updateWorkplace(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuração de local de trabalho salva com sucesso!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar configurações: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Local de Trabalho'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cartao explicativo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.lightBlue, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Defina as coordenadas da empresa. O ponto só poderá ser registrado quando o funcionário estiver a até ${_radiusController.text.isEmpty ? "100" : _radiusController.text}m deste local.',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nome da Empresa
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Posto / Empresa',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Latitude
                  TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude da Empresa',
                      prefixIcon: Icon(Icons.pin_drop_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Longitude
                  TextField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude da Empresa',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Raio Maximo (padrao 100m)
                  TextField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Raio Permitido (em metros)',
                      hintText: '100',
                      prefixIcon: Icon(Icons.radar_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botao para usar localizacao atual (facilitador de teste)
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Usar minha localização atual como Empresa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.lightBlue,
                      side: const BorderSide(color: AppTheme.lightBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botao de salvar
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveConfig,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Salvar Configurações'),
                  ),
                ],
              ),
            ),
    );
  }
}
