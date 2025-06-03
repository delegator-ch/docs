// lib/views/widgets/pending_invitations_widget.dart

import 'package:flutter/material.dart';
import '../../models/invitation.dart';

class PendingInvitationsWidget extends StatelessWidget {
  final List<Invitation> invitations;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final Function(Invitation) onAccept;
  final Function(Invitation) onDecline;

  const PendingInvitationsWidget({
    Key? key,
    required this.invitations,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Pending Invitations (${invitations.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (error != null)
              _buildErrorContainer(error!)
            else if (invitations.isEmpty)
              _buildEmptyState()
            else
              Column(
                children: invitations
                    .map((invitation) => _buildInvitationTile(invitation))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.mail_outline, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            'No pending invitations',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Organization invitations will appear here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationTile(Invitation invitation) {
    final isActive = invitation.canAccept && !invitation.isExpired;
    final statusColor = isActive ? Colors.green : Colors.red;
    final statusText = invitation.isExpired
        ? 'Expired'
        : (invitation.canAccept ? 'Active' : 'Inactive');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: isActive ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isActive
              ? BorderSide(color: Colors.green.withOpacity(0.3), width: 1)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.business,
                        color: Colors.orange[700], size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organization Invitation',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildInfoChip('Org ID: ${invitation.organisation}',
                            Icons.business),
                        const SizedBox(height: 4),
                        _buildInfoChip(
                            'Role ID: ${invitation.role}', Icons.person),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 13,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.code, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Code: ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        invitation.inviteCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.person, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'From: User ${invitation.invitedBy}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onDecline(invitation),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Decline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => onAccept(invitation),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accept & Join'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          invitation.isExpired
                              ? 'This invitation has expired and cannot be accepted'
                              : 'This invitation is not currently active',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
