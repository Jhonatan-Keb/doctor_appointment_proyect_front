import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateAppointmentDialog extends StatefulWidget {
  final String? motivoInicial;
  final String? medicoIdInicial;

  const CreateAppointmentDialog({
    super.key,
    this.motivoInicial,
    this.medicoIdInicial,
  });

  static Future<void> show(
    BuildContext context, {
    String? motivoInicial,
    String? medicoIdInicial,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateAppointmentDialog(
        motivoInicial: motivoInicial,
        medicoIdInicial: medicoIdInicial,
      ),
    );
  }

  @override
  State<CreateAppointmentDialog> createState() =>
      _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _motivoCtrl = TextEditingController();
  final TextEditingController _lugarCtrl = TextEditingController();
  final TextEditingController _notasCtrl = TextEditingController();

  String? _selectedDoctorId;
  DateTime _selectedDateTime =
      DateTime.now().add(const Duration(hours: 1));

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _motivoCtrl.text = widget.motivoInicial ?? '';
    _selectedDoctorId = widget.medicoIdInicial;
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _lugarCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _selectedDateTime.isAfter(now)
        ? _selectedDateTime
        : now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (timeOfDay == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
    });
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctorId == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Selecciona un doctor')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('citas').add({
        'userId': user.uid,
        'medicoId': _selectedDoctorId,
        'motivo': _motivoCtrl.text.trim(),
        'lugar': _lugarCtrl.text.trim(),
        'notas': _notasCtrl.text.trim(),
        'cuando': Timestamp.fromDate(_selectedDateTime),
        'estado': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Cita creada correctamente')),
      );
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Error al crear cita: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fechaStr =
        DateFormat('dd/MM/yyyy – HH:mm').format(_selectedDateTime);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear cita',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Completa la información para agendar tu cita.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _motivoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo / Título (ej. Consulta general)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el motivo de la cita';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _lugarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lugar / Clínica',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDateTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y hora',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fechaStr),
                        const Icon(Icons.edit_calendar_outlined),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ===== Dropdown de doctores (solo nombres reales) =====
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .where('rol', whereIn: ['Médico', 'medico'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Error al cargar médicos: ${snapshot.error}',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Doctor',
                          prefixIcon:
                              Icon(Icons.local_hospital_outlined),
                        ),
                        child: Text(
                          'Aún no hay cuentas de médicos.\n'
                          'Cuando se registren médicos, podrás seleccionarlos aquí.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedDoctorId,
                      decoration: const InputDecoration(
                        labelText: 'Doctor',
                        prefixIcon: Icon(Icons.local_hospital_outlined),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      items: docs.map((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final nombre =
                            (data['nombre'] ?? 'Médico') as String;

                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDoctorId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona un doctor';
                        }
                        return null;
                      },
                    );
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _notasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas adicionales (opcional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('Guardar cita'),
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

// ========= Wrapper para mantener tu API antigua =========

Future<void> showCreateAppointmentDialog(
  BuildContext context, {
  String? motivoSugerido,
  String? medicoIdSugerido,
}) {
  return CreateAppointmentDialog.show(
    context,
    motivoInicial: motivoSugerido,
    medicoIdInicial: medicoIdSugerido,
  );
}
