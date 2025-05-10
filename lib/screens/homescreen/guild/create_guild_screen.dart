// lib/screens/homescreen/guild/create_guild_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';

/// Diálogo para crear un gremio y subir imagen en orientación horizontal.
Future<void> showCreateGuildDialog(BuildContext context) async {
  final size = MediaQuery.of(context).size;
  final dialogWidth = size.width * 0.9;
  final dialogHeight = size.height * 0.8;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      // Ignorar viewInsets para evitar overflow con teclado
      final mq = MediaQuery.of(context);
      return MediaQuery(
        data: mq.copyWith(viewInsets: EdgeInsets.zero),
        child: Center(
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: const _CreateGuildDialog(),
          ),
        ),
      );
    },
  );
}

class _CreateGuildDialog extends StatefulWidget {
  const _CreateGuildDialog({Key? key}) : super(key: key);

  @override
  State<_CreateGuildDialog> createState() => _CreateGuildDialogState();
}

class _CreateGuildDialogState extends State<_CreateGuildDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _useAsset = true;
  final List<String> _assets = [
    'assets/guild_icons/icon1.png',
    'assets/guild_icons/icon2.png',
    'assets/guild_icons/icon3.png',
    'assets/guild_icons/icon4.png',
  ];
  String _selectedAsset = 'assets/guild_icons/icon1.png';
  XFile? _pickedImage;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<void> _createGuild() async {
    debugPrint('Creating guild...');
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del gremio es obligatorio.')),
      );
      return;
    }
    setState(() => _loading = true);
    final api = context.read<ApiService>();
final res = await api.createGuild(
  name,
  defaultIcon: _useAsset 
    ? _selectedAsset.split('/').last  // e.g. 'icon3.png'
    : null,
);
    if (res['status'] == 'ok' && res['guild_id'] != null) {
      final String guildId = res['guild_id'] as String;
      if (!_useAsset && _pickedImage != null) {
        await api.uploadGuildImage(guildId, File(_pickedImage!.path));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Gremio creado exitosamente.')),
      );
      Navigator.of(context).pop();
    } else {
      final String err = res['error'] ?? 'Error al crear gremio';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $err')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de imagen
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _useAsset = true;
                        _pickedImage = null;
                      }),
                      child: Text(
                        'Predeterminada',
                        style: TextStyle(
                          color: _useAsset ? Colors.orange : Colors.white54,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _useAsset = false;
                      }),
                      child: Text(
                        'Galería',
                        style: TextStyle(
                          color: !_useAsset ? Colors.orange : Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _useAsset ? null : _pickImage,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _useAsset
                        ? AssetImage(_selectedAsset) as ImageProvider
                        : (_pickedImage != null
                            ? FileImage(File(_pickedImage!.path))
                            : null),
                    child: _useAsset
                        ? DropdownButton<String>(
                            value: _selectedAsset,
                            dropdownColor: Colors.grey[900],
                            underline: const SizedBox(),
                            items: _assets
                                .map((a) => DropdownMenuItem(
                                      value: a,
                                      child: Image.asset(
                                        a,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedAsset = v!;
                              });
                            },
                          )
                        : (_pickedImage == null
                            ? const Icon(
                                Icons.camera_alt,
                                color: Colors.white54,
                                size: 36,
                              )
                            : null),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Formulario
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    maxLength: 12,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nombre',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      counterStyle:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLength: 60,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Descripción (opcional)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      counterStyle:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _loading ? null : _createGuild,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Crear',
                                style: TextStyle(color: Colors.black),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
