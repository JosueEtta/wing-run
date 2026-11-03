import 'package:flutter/material.dart';
import '../data/db.dart';
import '../theme.dart';

/// Shows the Add User dialog and returns the new user's name, or null if the
/// player cancelled.
///
/// [first] is true on the very first launch: there is no Cancel button, and
/// the dialog can't be closed by tapping outside or pressing the back button.
///
/// The returned name is already checked with [Session.validateName]
/// (not empty, at most 12 characters, not used by another user).
Future<String?> showAddUserDialog(BuildContext context, {bool first = false}) =>
    showNameDialog(context, first: first);

/// Shows the same dialog to rename [user]. Returns the new name, or null if
/// the player cancelled. The user's own name is allowed (nothing changes).
Future<String?> showRenameUserDialog(BuildContext context, AppUser user) =>
    showNameDialog(context,
        title: 'Rename User', initial: user.name, exceptId: user.id);

/// Shared by Add User and Rename User, so both use the same look and the
/// same naming rule.
Future<String?> showNameDialog(
    BuildContext context, {
      String title = 'Add User',
      String? initial,
      int? exceptId,
      bool first = false,
    }) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: !first,
    barrierLabel: 'Close',
    barrierColor: const Color(0x800F172A),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => _NameDialog(
      title: title,
      initial: initial,
      exceptId: exceptId,
      first: first,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        ),
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initial,
    required this.exceptId,
    required this.first,
  });

  final String title;
  final String? initial;
  final int? exceptId;
  final bool first;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  static const _red = Color(0xFFDC2626);

  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    // One rule for everyone: Session.validateName (also used by db.dart).
    final error =
    session.validateName(_controller.text, exceptId: widget.exceptId);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: 3),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.first,
      child: Padding(
        // Keeps the dialog visible when the keyboard opens (landscape!).
        padding: MediaQuery.viewInsetsOf(context),
        child: Center(
          child: SingleChildScrollView(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: C.navy, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: C.navy, width: 3),
                        ),
                      ),
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: C.navy,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.first
                                ? 'Enter a name to start playing.'
                                : 'User name',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _controller,
                            autofocus: true,
                            maxLength: Session.maxName,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            onChanged: (_) {
                              if (_error != null) setState(() => _error = null);
                            },
                            style: TextStyle(fontSize: 18, color: C.navy),
                            decoration: InputDecoration(
                              hintText: 'Enter user name',
                              errorText: _error,
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              enabledBorder: _border(C.navy),
                              focusedBorder: _border(C.blue),
                              errorBorder: _border(_red),
                              focusedErrorBorder: _border(_red),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!widget.first) ...[
                                OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: C.navy,
                                    minimumSize: const Size(96, 44),
                                    side: BorderSide(color: C.navy, width: 3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 10),
                              ],
                              FilledButton(
                                onPressed: _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _red,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(96, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: C.navy, width: 3),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}