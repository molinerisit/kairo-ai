import 'package:flutter/material.dart';
import '../../tables/table_service.dart';
import '../../../shared/theme/app_theme.dart';

// Widget de celda editable.
// En modo lectura muestra el valor como texto.
// Al hacer click, se convierte en un TextField inline.
// Al perder el foco (onEditingComplete / onTapOutside), guarda el valor.
class EditableCell extends StatefulWidget {
  final String rowId;
  final ColumnDefinition column;
  final dynamic value;
  final double width;
  final void Function(String rowId, String columnId, dynamic value) onSave;

  const EditableCell({
    super.key,
    required this.rowId,
    required this.column,
    required this.value,
    required this.onSave,
    this.width = 160,
  });

  @override
  State<EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<EditableCell> {
  bool _editing = false;
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl  = TextEditingController(text: _displayValue());
    _focus = FocusNode();
    _focus.addListener(() {
      // Cuando el foco se pierde, guardamos y salimos del modo edición
      if (!_focus.hasFocus && _editing) _save();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _displayValue() {
    if (widget.value == null) return '';
    return widget.value.toString();
  }

  void _save() {
    final val = _ctrl.text.trim();
    setState(() => _editing = false);
    if (val != _displayValue()) {
      widget.onSave(widget.rowId, widget.column.id, val);
    }
  }

  void _startEditing() {
    setState(() => _editing = true);
    // Pequeno delay para que el TextField se renderice antes de pedir foco
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: _editing ? _buildEditor() : _buildDisplay(),
    );
  }

  Widget _buildDisplay() {
    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: Text(
          _displayValue().isEmpty ? '—' : _displayValue(),
          style: TextStyle(
            fontSize: 13,
            color: _displayValue().isEmpty
                ? AppColors.textSecondary.withValues(alpha: 0.4)
                : AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1.5),
        color: AppColors.surfaceLight,
      ),
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          isDense: true,
        ),
        onSubmitted: (_) => _save(),
      ),
    );
  }
}
