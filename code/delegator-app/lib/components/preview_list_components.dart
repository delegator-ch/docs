// lib/components/preview_list_component.dart
import 'package:flutter/material.dart';

class PreviewListComponent extends StatelessWidget {
  final String title;
  final List<PreviewListItem> items;
  final VoidCallback onViewAllPressed;

  const PreviewListComponent({
    super.key,
    required this.title,
    required this.items,
    required this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: onViewAllPressed,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return InkWell(
              onTap: items[index].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[index].title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (items[index].subtitle != null)
                            Text(
                              items[index].subtitle!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class PreviewListItem {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  PreviewListItem({required this.title, this.subtitle, required this.onTap});
}
