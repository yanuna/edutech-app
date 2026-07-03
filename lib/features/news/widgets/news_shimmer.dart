import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NewsShimmer extends StatelessWidget {
  const NewsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, _) => const _ShimmerCard(),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 160,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source chip + date
                Row(
                  children: [
                    Container(width: 60, height: 22, color: Colors.white),
                    const SizedBox(width: 8),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 10),
                // Title lines
                Container(height: 14, color: Colors.white),
                const SizedBox(height: 6),
                Container(height: 14, width: 240, color: Colors.white),
                const SizedBox(height: 10),
                // Description
                Container(height: 11, color: Colors.white),
                const SizedBox(height: 4),
                Container(height: 11, width: 200, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
