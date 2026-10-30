import 'package:flutter/material.dart';
import '../data/db.dart';
import '../theme.dart';
import '../widgets/pixel_widgets.dart';

/// Round avatar + name. Tap -> panel with all users and "New user".
class UserSwitcher extends StatelessWidget {
  const UserSwitcher({super.key, this.onOpen, this.onClose});
  final VoidCallback? onOpen;

  /// Called when the panel closes; [changed] is true if the current user changed.
  final void Function(bool changed)? onClose;

  Future<void> _open(BuildContext context) async {
    onOpen?.call();
    final before = session.currentId;
    await showDialog(context: context, builder: (_) => const _UserPanel());
    onClose?.call(before != session.currentId);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (_, __) {
      if (session.users.isEmpty) return const SizedBox.shrink();
      final u = session.current;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(u.name,
                overflow: TextOverflow.ellipsis, style: body(24)),
          ),
          const SizedBox(width: 8),
          Avatar(u.initial),
        ]),
      );
    },
  );
}

class _UserPanel extends StatelessWidget {
  const _UserPanel();

  Future<void> _newUser(BuildContext context) async {
    final name = await showDialog<String>(
        context: context, builder: (_) => const _NewUserDialog());
    if (name != null && await session.addUser(name) && context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: pixelBox(color: Colors.white, shadow: 6),
      child: ListenableBuilder(
        listenable: session,
        builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
          Text('USERS', style: pixel(14)),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final u in session.users)
                GestureDetector(
                  onTap: () async {
                    await session.select(u.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    color: u.id == session.currentId ? C.highlight : C.slate,
                    child: Row(children: [
                      Avatar(u.initial, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(u.name,
                              overflow: TextOverflow.ellipsis, style: body(24))),
                      Text('${u.best}', style: pixel(10)),
                    ]),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          PixelButton(
            label: '+ NEW USER',
            fontSize: 10,
            color: C.blue,
            onTap: () => _newUser(context),
          ),
        ]),
      ),
    ),
  );
}

class _NewUserDialog extends StatefulWidget {
  const _NewUserDialog();
  @override
  State<_NewUserDialog> createState() => _NewUserDialogState();
}

class _NewUserDialogState extends State<_NewUserDialog> {
  final _c = TextEditingController();
  String? _error;

  void _submit() {
    final n = _c.text.trim();
    if (n.isEmpty) return setState(() => _error = 'Enter a name');
    if (session.users.any((u) => u.name.toLowerCase() == n.toLowerCase())) {
      return setState(() => _error = 'Name already used');
    }
    Navigator.pop(context, n);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: SingleChildScrollView(
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(16),
        decoration: pixelBox(color: Colors.white, shadow: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('ADD USER', style: pixel(14)),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            autofocus: true,
            maxLength: 12,
            style: body(26),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Enter user name',
              hintStyle: body(26, color: C.silver),
              errorText: _error,
              counterText: '',
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: C.navy, width: 3)),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: C.blue, width: 3)),
            ),
          ),
          const SizedBox(height: 12),
          PixelButton(label: 'OK', color: C.red, onTap: _submit),
        ]),
      ),
    ),
  );
}