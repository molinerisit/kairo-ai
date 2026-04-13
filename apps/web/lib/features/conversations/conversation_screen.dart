import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'conversation_provider.dart';
import 'conversation_service.dart';
import '../../shared/theme/app_theme.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final ConversationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ConversationProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.loadConversations());
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Panel izquierdo: lista de conversaciones
            const SizedBox(
              width: 320,
              child: _ConversationList(),
            ),
            const VerticalDivider(width: 1, color: AppColors.border),
            // Panel derecho: hilo de mensajes
            const Expanded(child: _MessageThread()),
          ],
        ),
      ),
    );
  }
}

// ── Panel izquierdo: lista de conversaciones ──────────────────────────────────

class _ConversationList extends StatelessWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationProvider>();

    return Column(
      children: [
        // Header con botón nueva conversación
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Conversaciones',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_comment_outlined, size: 20),
                color: AppColors.textSecondary,
                tooltip: 'Nueva conversación',
                onPressed: () => _showNewConversationDialog(context, provider),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Lista
        Expanded(
          child: provider.isLoadingList
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : provider.conversations.isEmpty
                  ? _buildEmpty(context, provider)
                  : ListView.builder(
                      itemCount: provider.conversations.length,
                      itemBuilder: (context, i) => _ConversationTile(
                        conversation: provider.conversations[i],
                        isSelected: provider.selected?.id == provider.conversations[i].id,
                        onTap: () => provider.selectConversation(provider.conversations[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, ConversationProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 40,
              color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('Sin conversaciones',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showNewConversationDialog(context, provider),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nueva conversación'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context, ConversationProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _NewConversationDialog(
        onCreated: (phone, name) => provider.createConversation(
          contactPhone: phone,
          contactName: name,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            // Avatar con inicial del contacto
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                _initial(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.contactName ?? conversation.contactPhone ?? 'Sin nombre',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge de estado
                      if (conversation.status != 'open')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor().withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _statusLabel(),
                            style: TextStyle(
                              color: _statusColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(_channelIcon(), size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        conversation.contactPhone ?? conversation.channel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  String _initial() {
    final name = conversation.contactName ?? conversation.contactPhone ?? '?';
    return name[0].toUpperCase();
  }

  Color _statusColor() => switch (conversation.status) {
    'resolved' => AppColors.success,
    'archived' => AppColors.textSecondary,
    _          => AppColors.primary,
  };

  String _statusLabel() => switch (conversation.status) {
    'resolved' => 'Resuelto',
    'archived' => 'Archivado',
    _          => 'Abierto',
  };

  IconData _channelIcon() => switch (conversation.channel) {
    'whatsapp' => Icons.chat,
    'web'      => Icons.language,
    _          => Icons.api,
  };
}

// ── Panel derecho: hilo de mensajes ──────────────────────────────────────────

class _MessageThread extends StatelessWidget {
  const _MessageThread();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationProvider>();

    if (provider.selected == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 48,
                color: Color(0x4D8B8B9E)), // textSecondary 30% opacity
            SizedBox(height: 12),
            Text('Seleccioná una conversación',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header del hilo
        _ThreadHeader(conversation: provider.selected!),
        const Divider(height: 1, color: AppColors.border),

        // Mensajes
        Expanded(
          child: provider.isLoadingMessages
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _MessageList(messages: provider.messages),
        ),

        // Input de mensaje
        const Divider(height: 1, color: AppColors.border),
        _MessageInput(onSend: (text) => provider.sendMessage(text)),
      ],
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  final Conversation conversation;
  const _ThreadHeader({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ConversationProvider>();
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              (conversation.contactName ?? conversation.contactPhone ?? '?')[0].toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.contactName ?? conversation.contactPhone ?? 'Sin nombre',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              if (conversation.contactPhone != null)
                Text(
                  conversation.contactPhone!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
            ],
          ),
          const Spacer(),
          // Botón resolver conversación
          if (conversation.status == 'open')
            OutlinedButton.icon(
              onPressed: () async {
                await ConversationService.updateStatus(conversation.id, 'resolved');
                await provider.loadConversations();
              },
              icon: const Icon(Icons.check_circle_outline, size: 14),
              label: const Text('Resolver', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageList extends StatefulWidget {
  final List<Message> messages;
  const _MessageList({required this.messages});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(_MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll al final cuando llegan mensajes nuevos
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(
        child: Text('Sin mensajes todavía',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: widget.messages.length,
      itemBuilder: (context, i) => _MessageBubble(message: widget.messages[i]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Los mensajes del asistente van a la izquierda, los del usuario a la derecha
    final isAssistant = message.role == 'assistant';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAssistant) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.smart_toy_outlined, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: isAssistant ? AppColors.surfaceLight : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(isAssistant ? 4 : 16),
                  bottomRight: Radius.circular(isAssistant ? 16 : 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAssistant && message.agentType != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _agentLabel(message.agentType!),
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isAssistant ? AppColors.textPrimary : Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAssistant) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _agentLabel(String type) => switch (type) {
    'secretary' => 'SECRETARIO',
    'vendor'    => 'VENDEDOR',
    'support'   => 'SOPORTE',
    _           => type.toUpperCase(),
  };
}

class _MessageInput extends StatefulWidget {
  final void Function(String) onSend;
  const _MessageInput({required this.onSend});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSending = context.watch<ConversationProvider>().isSending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Escribí un mensaje...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onSubmitted: (_) => _send(),
              maxLines: null, // permite multilínea
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedOpacity(
            opacity: isSending ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: IconButton(
              onPressed: isSending ? null : _send,
              icon: const Icon(Icons.send_rounded),
              color: AppColors.primary,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog nueva conversación ─────────────────────────────────────────────────

class _NewConversationDialog extends StatefulWidget {
  final void Function(String? phone, String? name) onCreated;
  const _NewConversationDialog({required this.onCreated});

  @override
  State<_NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<_NewConversationDialog> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl  = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Nueva conversación',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Nombre del contacto',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Teléfono (opcional)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: () {
            widget.onCreated(
              _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
              _nameCtrl.text.trim().isEmpty  ? null : _nameCtrl.text.trim(),
            );
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
