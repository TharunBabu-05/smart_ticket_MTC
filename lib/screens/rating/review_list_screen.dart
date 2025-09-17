import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rating_model.dart';
import '../../services/review_service.dart';
import '../../widgets/review_widgets.dart';
import 'review_submission_screen.dart';

class ReviewListScreen extends StatefulWidget {
  final String serviceId;
  final ReviewType reviewType;
  final String? serviceName;

  const ReviewListScreen({
    Key? key,
    required this.serviceId,
    required this.reviewType,
    this.serviceName,
  }) : super(key: key);

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<BusServiceRating> _reviews = [];
  ServiceMetrics? _metrics;
  bool _isLoading = true;
  String _searchQuery = '';
  SortOrder _sortOrder = SortOrder.newest;
  List<ServiceAspect> _filterAspects = [];
  double _minRating = 0.0;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMoreReviews = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reviewService = Provider.of<ReviewService>(context, listen: false);
      
      // Load metrics and reviews in parallel
      final results = await Future.wait([
        reviewService.getServiceMetrics(widget.serviceId, widget.reviewType),
        reviewService.getServiceReviews(
          serviceId: widget.serviceId,
          type: widget.reviewType,
          limit: 10,
          orderBy: _sortOrder.name,
        ),
      ]);

      setState(() {
        _metrics = results[0] as ServiceMetrics;
        _reviews = results[1] as List<BusServiceRating>;
        _hasMoreReviews = _reviews.length >= 10;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reviews: $e')),
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
      final newReviews = await reviewService.getServiceReviews(
        serviceId: widget.serviceId,
        type: widget.reviewType,
        limit: 10,
        orderBy: _sortOrder.name,
        lastDocumentId: _reviews.isNotEmpty ? _reviews.last.id : null,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        filterAspects: _filterAspects.isEmpty ? null : _filterAspects,
        minRating: _minRating > 0 ? _minRating : null,
      );

      setState(() {
        _reviews.addAll(newReviews);
        _hasMoreReviews = newReviews.length >= 10;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more reviews: $e')),
        );
      }
    }
  }

  Future<void> _refreshReviews() async {
    setState(() {
      _reviews.clear();
      _currentPage = 1;
      _hasMoreReviews = true;
    });
    await _loadInitialData();
  }

  void _applyFilters() async {
    setState(() {
      _isLoading = true;
      _reviews.clear();
      _currentPage = 1;
      _hasMoreReviews = true;
    });

    try {
      final reviewService = Provider.of<ReviewService>(context, listen: false);
      final filteredReviews = await reviewService.getServiceReviews(
        serviceId: widget.serviceId,
        type: widget.reviewType,
        limit: 10,
        orderBy: _sortOrder.name,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        filterAspects: _filterAspects.isEmpty ? null : _filterAspects,
        minRating: _minRating > 0 ? _minRating : null,
      );

      setState(() {
        _reviews = filteredReviews;
        _hasMoreReviews = filteredReviews.length >= 10;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying filters: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getServiceTypeLabel()} Reviews'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortBottomSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Reviews'),
            Tab(text: 'Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildReviewsTab(),
          _buildAnalysisTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToReviewSubmission,
        icon: const Icon(Icons.rate_review),
        label: const Text('Write Review'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_metrics == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _refreshReviews,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Info Card
            _buildServiceInfoCard(),
            const SizedBox(height: 16),
            
            // Metrics Summary
            ReviewSummaryWidget(metrics: _metrics!),
            const SizedBox(height: 16),
            
            // Recent Reviews Preview
            _buildRecentReviewsPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search reviews...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
        ),

        // Active Filters
        if (_filterAspects.isNotEmpty || _minRating > 0 || _searchQuery.isNotEmpty)
          _buildActiveFilters(),

        // Reviews List
        Expanded(
          child: _buildReviewsList(),
        ),
      ],
    );
  }

  Widget _buildAnalysisTab() {
    if (_metrics == null) {
      return const Center(child: Text('No analysis data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Trends Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating Trends',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        _metrics!.recentTrend > 0 
                            ? Icons.trending_up 
                            : Icons.trending_down,
                        color: _metrics!.recentTrend > 0 
                            ? Colors.green 
                            : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _metrics!.recentTrend > 0 
                                  ? 'Improving Quality' 
                                  : 'Declining Quality',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _metrics!.recentTrend > 0 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                            ),
                            Text(
                              'Based on recent reviews',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Aspect Analysis
          _buildAspectAnalysis(),

          const SizedBox(height: 16),

          // Common Feedback
          _buildCommonFeedback(),
        ],
      ),
    );
  }

  Widget _buildServiceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getServiceTypeIcon(),
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getServiceTypeLabel(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.serviceName ?? widget.serviceId,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (_metrics != null) ...[
              Column(
                children: [
                  Text(
                    _metrics!.averageRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(_metrics!.averageRating),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _metrics!.averageRating
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  Text(
                    '${_metrics!.totalReviews} reviews',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReviewsPreview() {
    final recentReviews = _reviews.take(3).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentReviews.map((review) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ServiceRatingCard(
                rating: review,
                showMetadata: false,
                onTap: () => _showReviewDetails(review),
              ),
            )),
            if (recentReviews.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No reviews yet'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const ReviewLoadingWidget(),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this service!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length + (_hasMoreReviews ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _reviews.length) {
            // Load more indicator
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _loadMoreReviews,
                  child: const Text('Load More Reviews'),
                ),
              );
            }
          }

          final review = _reviews[index];
          return ServiceRatingCard(
            rating: review,
            onTap: () => _showReviewDetails(review),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_searchQuery.isNotEmpty)
              _buildFilterChip(
                'Search: $_searchQuery',
                onRemove: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                  _applyFilters();
                },
              ),
            
            if (_minRating > 0)
              _buildFilterChip(
                '${_minRating.toInt()}+ stars',
                onRemove: () {
                  setState(() {
                    _minRating = 0.0;
                  });
                  _applyFilters();
                },
              ),
            
            ..._filterAspects.map((aspect) =>
              _buildFilterChip(
                _getAspectDisplayName(aspect),
                onRemove: () {
                  setState(() {
                    _filterAspects.remove(aspect);
                  });
                  _applyFilters();
                },
              ),
            ),
            
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _minRating = 0.0;
                  _filterAspects.clear();
                });
                _searchController.clear();
                _applyFilters();
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear All'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
      ),
    );
  }

  Widget _buildAspectAnalysis() {
    if (_metrics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Aspects Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Add aspect-wise breakdown from metrics
            Text(
              'Detailed analysis of service aspects will be shown here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonFeedback() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Common Feedback',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Add common tags/feedback analysis
            Text(
              'Most mentioned topics and feedback patterns will be shown here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getServiceTypeLabel() {
    switch (widget.reviewType) {
      case ReviewType.busService:
        return 'Bus Service';
      case ReviewType.route:
        return 'Route';
      case ReviewType.driver:
        return 'Driver';
      case ReviewType.station:
        return 'Bus Station';
    }
  }

  IconData _getServiceTypeIcon() {
    switch (widget.reviewType) {
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

  String _getAspectDisplayName(ServiceAspect aspect) {
    switch (aspect) {
      case ServiceAspect.punctuality:
        return 'Punctuality';
      case ServiceAspect.cleanliness:
        return 'Cleanliness';
      case ServiceAspect.driverBehavior:
        return 'Driver Behavior';
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

  void _showReviewDetails(BusServiceRating review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: ServiceRatingCard(rating: review),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Reviews',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Minimum Rating Filter
              Text(
                'Minimum Rating',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              StarRatingWidget(
                initialRating: _minRating,
                onRatingChanged: (rating) {
                  setBottomSheetState(() {
                    _minRating = rating;
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              // Aspect Filters
              Text(
                'Service Aspects',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ServiceAspect.values
                    .where((aspect) => aspect != ServiceAspect.overall)
                    .map((aspect) {
                  return FilterChip(
                    label: Text(_getAspectDisplayName(aspect)),
                    selected: _filterAspects.contains(aspect),
                    onSelected: (selected) {
                      setBottomSheetState(() {
                        if (selected) {
                          _filterAspects.add(aspect);
                        } else {
                          _filterAspects.remove(aspect);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {});
                    _applyFilters();
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...SortOrder.values.map((order) {
              return RadioListTile<SortOrder>(
                title: Text(_getSortOrderLabel(order)),
                value: order,
                groupValue: _sortOrder,
                onChanged: (value) {
                  setState(() {
                    _sortOrder = value!;
                  });
                  Navigator.of(context).pop();
                  _applyFilters();
                },
              );
            }),
          ],
        ),
      ),
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

  void _navigateToReviewSubmission() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewSubmissionScreen(
          serviceId: widget.serviceId,
          reviewType: widget.reviewType,
          serviceName: widget.serviceName,
        ),
      ),
    );

    // Refresh if a review was submitted
    if (result == true) {
      _refreshReviews();
    }
  }
}