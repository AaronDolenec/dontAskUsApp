import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';

/// Shimmer loading effect wrapper
class LoadingShimmer extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingShimmer({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: child,
    );
  }
}

/// Skeleton placeholder box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for question card
class QuestionCardSkeleton extends StatelessWidget {
  const QuestionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 100, height: 20),
              const SizedBox(height: 16),
              const SkeletonBox(height: 24),
              const SizedBox(height: 8),
              const SkeletonBox(width: 200, height: 24),
              const SizedBox(height: 24),
              ...List.generate(3, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonBox(height: 56, borderRadius: 12),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for member list item
class MemberItemSkeleton extends StatelessWidget {
  const MemberItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SkeletonBox(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 120, height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(width: 80, height: 12),
                ],
              ),
            ),
            const SkeletonBox(width: 60, height: 28, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for member list
class MemberListSkeleton extends StatelessWidget {
  final int count;

  const MemberListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) => const MemberItemSkeleton()),
    );
  }
}

/// Skeleton for history item
class HistoryItemSkeleton extends StatelessWidget {
  const HistoryItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 100, height: 14),
              SizedBox(height: 12),
              SkeletonBox(height: 20),
              SizedBox(height: 8),
              SkeletonBox(width: 200, height: 20),
              SizedBox(height: 16),
              Row(
                children: [
                  SkeletonBox(width: 80, height: 28, borderRadius: 14),
                  SizedBox(width: 12),
                  SkeletonBox(width: 100, height: 28, borderRadius: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for history list
class HistoryListSkeleton extends StatelessWidget {
  final int count;

  const HistoryListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) => const HistoryItemSkeleton()),
    );
  }
}

/// Full page loading indicator
class LoadingPage extends StatelessWidget {
  final String? message;

  const LoadingPage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
