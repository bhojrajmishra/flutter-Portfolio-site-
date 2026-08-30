import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/portfolio_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../window_manager.dart';

class ContactWindowContent extends ConsumerStatefulWidget {
  const ContactWindowContent({super.key});

  @override
  ConsumerState<ContactWindowContent> createState() => _ContactWindowContentState();
}

class _ContactWindowContentState extends ConsumerState<ContactWindowContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    // Consume a one-shot draft left by the Calendar window's "Request via
    // Contact" action, if any — cleared right away so it doesn't reappear
    // if the visitor closes and reopens Contact later.
    final prefill = ref.read(contactPrefillProvider);
    if (prefill != null && prefill.isNotEmpty) {
      _messageController.text = prefill;
      Future.microtask(() => ref.read(contactPrefillProvider.notifier).set(null));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _resultMessage = null;
    });
    try {
      await ref.read(portfolioRepositoryProvider).sendContactMessage(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            message: _messageController.text.trim(),
          );
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
      setState(() => _resultMessage = 'Thanks — your message has been sent.');
    } catch (_) {
      setState(() => _resultMessage = 'Something went wrong. Please try again.');
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send Message'),
                ),
                if (_resultMessage != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(_resultMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
