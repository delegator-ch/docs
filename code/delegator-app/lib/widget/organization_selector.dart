// lib/widgets/organization_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_organisation.dart';
import '../providers/organization_context_provider.dart';

/// A dropdown widget for selecting the current organization
class OrganizationSelector extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const OrganizationSelector({
    Key? key,
    this.showLabel = true,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationContextProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading organizations...'),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error: ${provider.error}',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: provider.refresh,
                ),
              ],
            ),
          );
        }

        if (!provider.hasOrganizations) {
          return Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[600], size: 16),
                const SizedBox(width: 8),
                const Text(
                  'No organizations available',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: backgroundColor != null
              ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel) ...[
                Text(
                  'Current Organization',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              DropdownButtonFormField<UserOrganisation>(
                value: provider.currentOrganization,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  prefixIcon:
                      Icon(Icons.business, size: 18, color: Colors.grey[600]),
                ),
                items: provider.userOrganizations.map((userOrg) {
                  return DropdownMenuItem<UserOrganisation>(
                    value: userOrg,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                userOrg.organisationDetails?.name ??
                                    'Organization #${userOrg.organisation}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (userOrg.roleDetails != null)
                                Text(
                                  userOrg.roleDetails!.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ID: ${userOrg.organisation}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (UserOrganisation? newOrg) {
                  if (newOrg != null) {
                    provider.setCurrentOrganization(newOrg);
                  }
                },
                hint: const Text('Select organization'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact version for app bars or tight spaces
class CompactOrganizationSelector extends StatelessWidget {
  const CompactOrganizationSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationContextProvider>(
      builder: (context, provider, child) {
        if (!provider.hasOrganizations ||
            provider.currentOrganization == null) {
          return const SizedBox.shrink();
        }

        return PopupMenuButton<UserOrganisation>(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business,
                    size: 16, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 6),
                Text(
                  provider.currentOrganization!.organisationDetails?.name ??
                      'Org #${provider.currentOrganization!.organisation}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down,
                    size: 16, color: Colors.white.withOpacity(0.7)),
              ],
            ),
          ),
          itemBuilder: (context) => provider.userOrganizations.map((userOrg) {
            return PopupMenuItem<UserOrganisation>(
              value: userOrg,
              child: Row(
                children: [
                  Icon(
                    provider.currentOrganization?.organisation ==
                            userOrg.organisation
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: provider.currentOrganization?.organisation ==
                            userOrg.organisation
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userOrg.organisationDetails?.name ??
                              'Organization #${userOrg.organisation}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (userOrg.roleDetails != null)
                          Text(
                            userOrg.roleDetails!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onSelected: (UserOrganisation newOrg) {
            provider.setCurrentOrganization(newOrg);
          },
        );
      },
    );
  }
}

class OrganizationSelectorCard extends StatelessWidget {
  const OrganizationSelectorCard({Key? key}) : super(key: key);

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
                Icon(Icons.business, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Current Organization',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OrganizationSelector(
              showLabel: false,
              backgroundColor: Colors.grey[50],
            ),
          ],
        ),
      ),
    );
  }
}
