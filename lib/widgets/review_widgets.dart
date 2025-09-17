import 'package:flutter/material.dart';
import '../models/rating_model.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Interactive Star Rating Widget
class StarRatingWidget extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final bool isEnabled;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;
  final String label;

  const StarRatingWidget({
    Key? key,
    required this.initialRating,
    required this.onRatingChanged,
    this.isEnabled = true,
    this.activeColor,
    this.inactiveColor,
    this.size = 30.0,
    this.label = '',
  }) : super(key: key);

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.amber;
    final inactiveColor = widget.inactiveColor ?? Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: widget.isEnabled
                  ? () {
                      setState(() {
                        _currentRating = (index + 1).toDouble();
                      });
                      widget.onRatingChanged(_currentRating);
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  index < _currentRating ? Icons.star : Icons.star_border,
                  color: index < _currentRating ? activeColor : inactiveColor,
                  size: widget.size,
                ),
              ),
            );
          }),
        ),
        if (_currentRating > 0)
          Text(
            _currentRating == 1 ? '1 star' : '${_currentRating.toInt()} stars',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Service Rating Card Widget
class ServiceRatingCard extends StatelessWidget {
  final BusServiceRating rating;
  final VoidCallback? onTap;
  final bool showMetadata;

  const ServiceRatingCard({
    Key? key,
    required this.rating,
    this.onTap,
    this.showMetadata = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and overall rating
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      rating.userName.isNotEmpty 
                          ? rating.userName[0].toUpperCase() 
                          : 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              rating.userName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (rating.isVerified) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          timeago.format(rating.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Overall rating badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRatingColor(rating.overallRating).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getRatingColor(rating.overallRating)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: _getRatingColor(rating.overallRating),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.overallRating.toStringAsFixed(1),
                          style: TextStyle(
                            color: _getRatingColor(rating.overallRating),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Service info chip
              if (showMetadata)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getReviewTypeIcon(rating.reviewType),
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${rating.reviewType.toString().split('.').last.toUpperCase()} ${rating.serviceId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Review comment
              if (rating.comment.isNotEmpty) ...[
                Text(
                  rating.comment,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Aspect ratings preview (top 3)
              AspectRatingsWidget(
                aspectRatings: rating.aspectRatings,
                isCompact: true,
              ),

              const SizedBox(height: 12),

              // Action row
              Row(
                children: [
                  // Helpful votes
                  Row(
                    children: [
                      Icon(
                        Icons.thumb_up_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${rating.helpfulVotes}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Response count if any
                  if (rating.hasResponse) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Response',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // More actions button
                  IconButton(
                    onPressed: () => _showMoreActions(context, rating),
                    icon: const Icon(Icons.more_horiz),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  IconData _getReviewTypeIcon(ReviewType type) {
    switch (type) {
      case ReviewType.busService:
        return Icons.directions_bus;
      case ReviewType.route:
        return Icons.route;
      case ReviewType.driver:
        return Icons.person;
      case ReviewType.station:
        return Icons.location_on;
    }
  }

  void _showMoreActions(BuildContext context, BusServiceRating rating) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Review'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report Review'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Aspect Ratings Widget
class AspectRatingsWidget extends StatelessWidget {
  final Map<ServiceAspect, double> aspectRatings;
  final bool isCompact;
  final bool isEditable;
  final Function(ServiceAspect, double)? onRatingChanged;

  const AspectRatingsWidget({
    Key? key,
    required this.aspectRatings,
    this.isCompact = false,
    this.isEditable = false,
    this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final aspectsToShow = isCompact 
        ? aspectRatings.entries.take(3).toList()
        : aspectRatings.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompact) ...[
          Text(
            'Service Aspects',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...aspectsToShow.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: isCompact ? 80 : 120,
                  child: Text(
                    _getAspectDisplayName(entry.key),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (isEditable) ...[
                  Expanded(
                    child: StarRatingWidget(
                      initialRating: entry.value,
                      onRatingChanged: (rating) {
                        onRatingChanged?.call(entry.key, rating);
                      },
                      size: 20,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < entry.value ? Icons.star : Icons.star_border,
                            size: isCompact ? 16 : 20,
                            color: index < entry.value 
                                ? Colors.amber 
                                : Colors.grey.shade300,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          entry.value.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getRatingColor(entry.value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        if (isCompact && aspectRatings.length > 3) ...[
          const SizedBox(height: 8),
          Text(
            '... and ${aspectRatings.length - 3} more aspects',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _getAspectDisplayName(ServiceAspect aspect) {
    switch (aspect) {
      case ServiceAspect.punctuality:
        return 'Punctuality';
      case ServiceAspect.cleanliness:
        return 'Cleanliness';
      case ServiceAspect.driverBehavior:
        return 'Driver';
      case ServiceAspect.comfort:
        return 'Comfort';
      case ServiceAspect.safety:
        return 'Safety';
      case ServiceAspect.overall:
        return 'Overall';
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }
}

/// Review Summary Widget
class ReviewSummaryWidget extends StatelessWidget {
  final ServiceMetrics metrics;

  const ReviewSummaryWidget({
    Key? key,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Main stats row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Average Rating',
                    value: metrics.averageRating.toStringAsFixed(1),
                    subtitle: 'out of 5.0',
                    color: _getRatingColor(metrics.averageRating),
                    icon: Icons.star,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Total Reviews',
                    value: metrics.totalReviews.toString(),
                    subtitle: 'reviews',
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.reviews,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Recommended',
                    value: '${(metrics.averageRating >= 4.0 ? ((metrics.averageRating - 3.0) * 100).toInt() : 0)}%',
                    subtitle: 'would recommend',
                    color: Colors.green,
                    icon: Icons.thumb_up,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Rating distribution
            Text(
              'Rating Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...List.generate(5, (index) {
              final star = 5 - index;
              final count = metrics.ratingDistribution[star] ?? 0;
              final percentage = metrics.totalReviews > 0 
                  ? (count / metrics.totalReviews) 
                  : 0.0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Row(
                        children: [
                          Text('$star'),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Recent trend
            if (metrics.recentTrend != 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: metrics.recentTrend > 0 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: metrics.recentTrend > 0 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      metrics.recentTrend > 0 
                          ? Icons.trending_up 
                          : Icons.trending_down,
                      color: metrics.recentTrend > 0 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        metrics.recentTrend > 0 
                            ? 'Service quality improving recently'
                            : 'Service quality needs attention',
                        style: TextStyle(
                          color: metrics.recentTrend > 0 
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }
}

/// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Loading Widget for Reviews
class ReviewLoadingWidget extends StatelessWidget {
  const ReviewLoadingWidget({Key? key}) : super(key: key);

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
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}