import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rating_model.dart';
import '../../services/review_service.dart';
import '../../widgets/review_widgets.dart';
import '../../themes/app_theme.dart';
import 'review_submission_screen.dart';

class AllReviewsScreen extends StatefulWidget {
  const AllReviewsScreen({Key? key}) : super(key: key);

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<BusServiceRating> _allReviews = [];
  List<BusServiceRating> _filteredReviews = [];
  bool _isLoading = true;
  String _searchQuery = '';
  SortOrder _sortOrder = SortOrder.newest;
  ReviewType? _filterType;
  double _minRating = 0.0;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMoreReviews = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reviewService = Provider.of<ReviewService>(context, listen: false);
      
      // Load recent reviews from all services
      final reviews = await reviewService.getRecentReviews(limit: _pageSize);

      setState(() {
        _allReviews = reviews;
        _filteredReviews = reviews;
        _hasMoreReviews = reviews.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reviews: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || !_hasMoreReviews) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final reviewService = Provider.of<ReviewService>(context, listen: false);
      
      // Calculate offset for pagination
      final offset = _currentPage * _pageSize;
      final newReviews = await reviewService.getRecentReviews(
        limit: _pageSize,
        // Note: This is a simplified pagination - in production, you'd want proper cursor-based pagination
      );

      // Get only the new items (simple approach - in production use proper pagination)
      final startIndex = _allReviews.length;
      final relevantNewReviews = newReviews.skip(startIndex).take(_pageSize).toList();

      setState(() {
        _allReviews.addAll(relevantNewReviews);
        _applyFilters();
        _hasMoreReviews = relevantNewReviews.length >= _pageSize;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more reviews: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshReviews() async {
    setState(() {
      _allReviews.clear();
      _filteredReviews.clear();
      _currentPage = 1;
      _hasMoreReviews = true;
    });
    await _loadAllReviews();
  }

  void _applyFilters() {
    List<BusServiceRating> filtered = List.from(_allReviews);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((review) {
        return review.comment.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               review.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               review.busNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               review.routeName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    if (_filterType != null) {
      filtered = filtered.where((review) => review.reviewType == _filterType).toList();
    }

    // Apply rating filter
    if (_minRating > 0) {
      filtered = filtered.where((review) => review.overallRating >= _minRating).toList();
    }

    // Apply sorting
    switch (_sortOrder) {
      case SortOrder.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOrder.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOrder.highestRated:
        filtered.sort((a, b) => b.overallRating.compareTo(a.overallRating));
        break;
      case SortOrder.lowestRated:
        filtered.sort((a, b) => a.overallRating.compareTo(b.overallRating));
        break;
      case SortOrder.mostHelpful:
        filtered.sort((a, b) => b.helpfulVotes.compareTo(a.helpfulVotes));
        break;
    }

    setState(() {
      _filteredReviews = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ThemedScaffold(
      title: 'All Reviews',
      actions: [
        // Debug: Add sample data button (development only)
        if (const bool.fromEnvironment('DEBUG', defaultValue: true))
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              final reviewService = Provider.of<ReviewService>(context, listen: false);
              await reviewService.addSampleReviewData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sample review data added!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              _refreshReviews();
            },
            tooltip: 'Add Sample Data',
          ),
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: _showFilterBottomSheet,
          tooltip: 'Filter Reviews',
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortBottomSheet,
          tooltip: 'Sort Reviews',
        ),
      ],
      body: Column(
        children: [
          // Search Bar with consistent AppTheme styling
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: AppTheme.createCardDecoration(context),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: AppTheme.getPrimaryTextColor(context),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search reviews, users, or services...',
                  hintStyle: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          
          // Reviews List
          Expanded(
            child: _buildReviewsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReviewSubmissionScreen(
                serviceId: 'general',
                reviewType: ReviewType.busService,
                serviceName: 'General Feedback',
              ),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: Text(
          'Write Review',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.rate_review_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reviews Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your travel experience!\nYour feedback helps improve our services.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReviewSubmissionScreen(
                      serviceId: 'general',
                      reviewType: ReviewType.busService,
                      serviceName: 'General Feedback',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Write a Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshReviews,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoadingMore &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _loadMoreReviews();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredReviews.length + (_hasMoreReviews ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _filteredReviews.length) {
              return _isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink();
            }

            final review = _filteredReviews[index];
            return _buildReviewCard(review);
          },
        ),
      ),
    );
  }

  Widget _buildReviewCard(BusServiceRating review) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.createCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage: review.userAvatar.isNotEmpty
                      ? NetworkImage(review.userAvatar)
                      : null,
                  child: review.userAvatar.isEmpty
                      ? Text(
                          review.userName.isNotEmpty 
                              ? review.userName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // User info and service details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              review.userName,
                              style: TextStyle(
                                color: AppTheme.getPrimaryTextColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (review.isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getServiceDescription(review),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getRelativeTime(review.createdAt),
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Overall Rating
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRatingColor(review.overallRating),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        review.overallRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Review Title (if available)
            if (review.reviewTitle.isNotEmpty && review.reviewTitle != review.comment) ...[
              const SizedBox(height: 16),
              Text(
                review.reviewTitle,
                style: TextStyle(
                  color: AppTheme.getPrimaryTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            
            // Review Content
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackground(context).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getCardBorderColor(context),
                  ),
                ),
                child: Text(
                  review.comment,
                  style: TextStyle(
                    color: AppTheme.getPrimaryTextColor(context),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            
            // Tags
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: review.tags.take(3).map((tag) {
                  final isPositive = ['Clean', 'Punctual', 'Good Service', 'Professional', 'Helpful', 'Recommend', 'AC Working', 'Cost Effective'].contains(tag);
                  final isNegative = ['Crowded', 'Delayed', 'Breakdown', 'Poor Maintenance', 'Needs Improvement'].contains(tag);
                  
                  Color tagColor = theme.colorScheme.primary;
                  if (isPositive) tagColor = Colors.green;
                  if (isNegative) tagColor = Colors.orange;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _voteHelpful(review),
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Helpful (${review.helpfulVotes})'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.getSecondaryTextColor(context),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _shareReview(review),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Share'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.getSecondaryTextColor(context),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                if (review.hasResponse) ...[
                  TextButton.icon(
                    onPressed: () => _viewResponse(review),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('View Response'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getServiceDescription(BusServiceRating review) {
    switch (review.reviewType) {
      case ReviewType.busService:
        return 'Bus ${review.busNumber} • ${review.routeName}';
      case ReviewType.route:
        return 'Route ${review.routeName}';
      case ReviewType.driver:
        return 'Driver • Bus ${review.busNumber}';
      case ReviewType.station:
        return 'Station • ${review.boardingPoint}';
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _voteHelpful(BusServiceRating review) async {
    try {
      final reviewService = Provider.of<ReviewService>(context, listen: false);
      await reviewService.voteOnReview(review.id, true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      
      // Refresh the reviews to show updated vote count
      _refreshReviews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error voting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareReview(BusServiceRating review) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _viewResponse(BusServiceRating review) {
    // Implement view response functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Response viewing coming soon!')),
    );
  }

  String _getSortOrderLabel(SortOrder order) {
    switch (order) {
      case SortOrder.newest:
        return 'Newest First';
      case SortOrder.oldest:
        return 'Oldest First';
      case SortOrder.highestRated:
        return 'Highest Rated';
      case SortOrder.lowestRated:
        return 'Lowest Rated';
      case SortOrder.mostHelpful:
        return 'Most Helpful';
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Minimum Rating:'),
            const SizedBox(height: 10),
            Slider(
              value: _minRating,
              min: 0,
              max: 5,
              onChanged: (value) {
                setState(() {
                  _minRating = value;
                });
              },
              divisions: 10,
              label: _minRating == 0 ? 'Any' : '${_minRating.toStringAsFixed(1)}+',
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minRating = 0;
                      _filterType = null;
                    });
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...SortOrder.values.map((order) => ListTile(
              title: Text(_getSortOrderLabel(order)),
              leading: Radio<SortOrder>(
                value: order,
                groupValue: _sortOrder,
                onChanged: (SortOrder? value) {
                  if (value != null) {
                    setState(() {
                      _sortOrder = value;
                    });
                    Navigator.pop(context);
                    _applyFilters();
                  }
                },
              ),
            )),
          ],
        ),
      ),
    );
  }
}