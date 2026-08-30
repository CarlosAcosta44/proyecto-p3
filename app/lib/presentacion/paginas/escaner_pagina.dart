import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../providers/inventario_estado_provider.dart';

class EscanerPagina extends ConsumerStatefulWidget {
  const EscanerPagina({super.key});

  @override
  ConsumerState<EscanerPagina> createState() => _EscanerPaginaState();
}

class _EscanerPaginaState extends ConsumerState<EscanerPagina> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _procesando = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture captura) async {
    final codigo = captura.barcodes.first.rawValue;
    if (codigo == null || _procesando) return;
    
    setState(() => _procesando = true);
    
    final items = ref.read(inventarioProvider).items;
    final index = items.indexWhere((i) => i.codigoBarras == codigo);
    
    if (index == -1) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código desconocido o no pertenece a este lote')),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _procesando = false);
      return;
    }
    
    final item = items[index];
    HapticFeedback.lightImpact();

    if (mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _EdicionItemModal(
          codigo: codigo,
          nombre: item.nombre,
          cantidadActual: item.cantidad,
          estadoActual: item.estado,
          alGuardar: (cantidad, estado, foto) async {
            await ref.read(inventarioProvider.notifier).registrarConteo(
              codigo, cantidad, estado: estado, fotoRuta: foto
            );
            if (ctx.mounted) Navigator.pop(ctx);
          }
        )
      );
    }
    
    if (mounted) setState(() => _procesando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escáner Continuo'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          if (_procesando)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF39A900))),
            ),
        ],
      ),
    );
  }
}

class _EdicionItemModal extends StatefulWidget {
  final String codigo;
  final String nombre;
  final int cantidadActual;
  final String estadoActual;
  final Function(int cantidad, String estado, String? fotoBase64) alGuardar;

  const _EdicionItemModal({
    required this.codigo,
    required this.nombre,
    required this.cantidadActual,
    required this.estadoActual,
    required this.alGuardar,
  });

  @override
  State<_EdicionItemModal> createState() => _EdicionItemModalState();
}

class _EdicionItemModalState extends State<_EdicionItemModal> {
  late TextEditingController _cantCtrl;
  late String _estado;
  String? _fotoBase64;
  bool _comprimiendo = false;

  @override
  void initState() {
    super.initState();
    _cantCtrl = TextEditingController(text: widget.cantidadActual.toString());
    _estado = widget.estadoActual.isEmpty ? 'bueno' : widget.estadoActual;
  }

  Future<void> _tomarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    
    if (foto != null) {
      setState(() => _comprimiendo = true);
      final result = await FlutterImageCompress.compressWithFile(
        foto.path,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );
      if (result != null) {
        setState(() {
          _fotoBase64 = base64Encode(result);
          _comprimiendo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Código: ${widget.codigo}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _cantCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cantidad Física', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _estado,
            decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'bueno', child: Text('Bueno')),
              DropdownMenuItem(value: 'regular', child: Text('Regular')),
              DropdownMenuItem(value: 'averiado', child: Text('Averiado')),
            ],
            onChanged: (val) => setState(() => _estado = val ?? 'bueno'),
          ),
          const SizedBox(height: 16),
          if (_estado == 'averiado') ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_fotoBase64 != null ? 'Foto Capturada' : 'Tomar Foto de Evidencia'),
              onPressed: _comprimiendo ? null : _tomarFoto,
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39A900), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () {
              final cant = int.tryParse(_cantCtrl.text) ?? widget.cantidadActual;
              widget.alGuardar(cant, _estado, _fotoBase64);
            },
            child: const Text('Confirmar Conteo', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
