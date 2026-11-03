import 'package:flutter/material.dart';
import '../data/db.dart';
import '../theme.dart';
import 'add_user_dialog.dart';

/// Opens the "Manage users" panel: rename or delete any user.
Future<void> showManageUsers(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _ManageUsersDialog());

class _ManageUsersDialog extends StatelessWidget {
  const _ManageUsersDialog();

  Future<void> _rename(BuildContext context, AppUser u) async {
    final name = await showRenameUserDialog(context, u);
    if (name != null) await session.renameUser(u.id, name);
  }

  Future<void> _delete(BuildContext context, AppUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${u.name}?'),
        content: const Text('Their best score will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await session.deleteUser(u.id);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: C.navy, width: 3),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 300),
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            final users = session.users;
            final onlyOne = users.length <= 1;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  const Expanded(
                    child: Text('Manage users',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: C.navy)),
                  ),
                  IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ]),
                Flexible(
                  child: ListView(shrinkWrap: true, children: [
                    for (final u in users)
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(right: 4),
                        leading: CircleAvatar(
                          backgroundColor: C.navy,
                          foregroundColor: Colors.white,
                          child: Text(u.initial),
                        ),
                        title: Text(u.name,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            'Best ${u.best}${u.id == session.currentId ? ' · current' : ''}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: 'Rename',
                            icon: const Icon(Icons.edit),
                            onPressed: () => _rename(context, u),
                          ),
                          IconButton(
                            tooltip: onlyOne
                                ? 'At least one user must remain'
                                : 'Delete',
                            icon: Icon(Icons.delete,
                                color: onlyOne ? null : C.red),
                            onPressed:
                            onlyOne ? null : () => _delete(context, u),
                          ),
                        ]),
                      ),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}