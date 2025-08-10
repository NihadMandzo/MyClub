import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/responses/comment_response.dart';
import '../providers/auth_provider.dart';
import '../utility/responsive_helper.dart';

class CommentsWidget extends StatefulWidget {
  final List<CommentResponse> comments;
  final Function(CommentResponse) onCommentAdded;
  final Function(CommentResponse) onCommentUpdated;
  final Function(CommentResponse) onCommentDeleted;

  const CommentsWidget({
    super.key,
    required this.comments,
    required this.onCommentAdded,
    required this.onCommentUpdated,
    required this.onCommentDeleted,
  });

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  CommentResponse? _editingComment;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dialog height based on number of comments
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.8;
    
    // Ensure minimum height for empty state
    final minHeight = 300.0;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: maxDialogHeight,
          minHeight: minHeight,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            
            // Comments list (scrollable)
            Expanded(
              child: _buildCommentsList(),
            ),
            
            // Comment input (fixed at bottom)
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment,
            color: Colors.white,
            size: ResponsiveHelper.iconSize(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Komentari',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (widget.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.comment_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nema komentara',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 16),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = widget.comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(CommentResponse comment) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwnComment = authProvider.username == comment.username;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              Icon(
                Icons.person,
                size: ResponsiveHelper.font(context, base: 14),
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                comment.username,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 12),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${comment.createdAt.day.toString().padLeft(2, '0')}.${comment.createdAt.month.toString().padLeft(2, '0')}.${comment.createdAt.year}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 10),
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              if (isOwnComment) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _editComment(comment),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit,
                          size: ResponsiveHelper.font(context, base: 16),
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _deleteComment(comment),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete,
                          size: ResponsiveHelper.font(context, base: 16),
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Comment content
          Text(
            comment.content,
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 14),
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          if (_editingComment != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    size: ResponsiveHelper.font(context, base: 14),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Uređujete komentar',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, base: 12),
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('Otkaži'),
                  ),
                ],
              ),
            ),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _editingComment != null 
                        ? 'Uredite komentar...' 
                        : 'Dodajte komentar...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editComment(CommentResponse comment) {
    setState(() {
      _editingComment = comment;
      _commentController.text = comment.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingComment = null;
      _commentController.clear();
    });
  }

  void _deleteComment(CommentResponse comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši komentar'),
        content: const Text('Da li ste sigurni da želite obrisati ovaj komentar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCommentDeleted(comment);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Komentar je obrisan')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
  }

  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (_editingComment != null) {
        // Update existing comment
        final updatedComment = CommentResponse(
          id: _editingComment!.id,
          content: content,
          createdAt: _editingComment!.createdAt,
          username: _editingComment!.username,
        );
        
        widget.onCommentUpdated(updatedComment);
        setState(() {
          _editingComment = null;
          _commentController.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar je ažuriran')),
        );
      } else {
        // Add new comment
        final newComment = CommentResponse(
          id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          content: content,
          createdAt: DateTime.now(),
          username: authProvider.username ?? 'Nepoznat korisnik',
        );
        
        widget.onCommentAdded(newComment);
        _commentController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar je dodan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
