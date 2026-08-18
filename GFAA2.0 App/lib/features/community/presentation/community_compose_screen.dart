import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../application/community_providers.dart';

/// Pops with `true` on a successful post (so the feed screen — which
/// doesn't know here whether the post landed approved or pending — can
/// show the right confirmation), or `null`/`false` if nothing was posted.
class CommunityComposeScreen extends ConsumerStatefulWidget {
  const CommunityComposeScreen({super.key});

  @override
  ConsumerState<CommunityComposeScreen> createState() => _CommunityComposeScreenState();
}

class _CommunityComposeScreenState extends ConsumerState<CommunityComposeScreen> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (_controller.text.trim().isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this post?'),
        content: const Text("You'll lose what you've written."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard')),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _post() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    final userId = ref.read(currentUserIdProvider);
    final profile = ref.read(profileProvider).value;
    if (userId == null || profile == null) return;

    setState(() => _isPosting = true);
    try {
      await ref.read(communityRepositoryProvider).createPost(
            authorId: userId,
            authorDisplayName: profile.effectiveDisplayName,
            body: body,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't post: $error")));
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isPosting ? null : _handleBack,
          ),
          title: const Text('New post'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isPosting ? null : _post,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                letterSpacing: 0.1,
                color: AppColors.nearBlack,
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                hintText: 'Share something with the group…',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
