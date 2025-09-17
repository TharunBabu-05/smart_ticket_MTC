import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rating_model.dart';
import '../../services/review_service.dart';
import '../../widgets/review_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewSubmissionScreen extends StatefulWidget {
  final String serviceId;
  final ReviewType reviewType;
  final String? serviceName;
  final BusServiceRating? existingReview;

  const ReviewSubmissionScreen({
    Key? key,
    required this.serviceId,
    required this.reviewType,
    this.serviceName,
    this.existingReview,
  }) : super(key: key);

  @override
  State<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  Map<ServiceAspect, double> _aspectRatings = {};
  double _overallRating = 0.0;
  String _comment = '';
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  List<String> _selectedPhotos = [];

  // Predefined common tags for quick selection
  final List<String> _commonTags = [
    'Clean', 'Punctual', 'Crowded', 'Comfortable', 'Safe',
    'Delayed', 'Rude Driver', 'AC Working', 'Smooth Ride',
    'Good Service', 'Needs Improvement', 'Recommend'
  ];
  
  Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _initializeRatings();
    _loadExistingReview();
  }

  void _initializeRatings() {
    // Initialize all aspects with 0 rating
    for (ServiceAspect aspect in ServiceAspect.values) {
      if (aspect != ServiceAspect.overall) {
        _aspectRatings[aspect] = 0.0;
      }
    }
  }

  void _loadExistingReview() {
    if (widget.existingReview != null) {
      final review = widget.existingReview!;
      setState(() {
        _aspectRatings = Map.from(review.aspectRatings);
        _overallRating = review.overallRating;
        _comment = review.comment;
        _commentController.text = _comment;
        _isAnonymous = review.isAnonymous;
        _selectedTags = Set.from(review.tags);
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingReview != null ? 'Edit Review' : 'Rate Service'),
        elevation: 0,
        actions: [
          if (widget.existingReview != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Info Card
              _buildServiceInfoCard(),
              const SizedBox(height: 20),

              // Overall Rating Section
              _buildOverallRatingSection(),
              const SizedBox(height: 24),

              // Aspect Ratings Section
              _buildAspectRatingsSection(),
              const SizedBox(height: 24),

              // Comment Section
              _buildCommentSection(),
              const SizedBox(height: 24),

              // Quick Tags Section
              _buildQuickTagsSection(),
              const SizedBox(height: 24),

              // Photo Upload Section
              _buildPhotoSection(),
              const SizedBox(height: 24),

              // Privacy Settings
              _buildPrivacySection(),
              const SizedBox(height: 24),

              // Rating Summary
              _buildRatingSummary(),
              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Experience',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you rate your overall experience?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: StarRatingWidget(
                initialRating: _overallRating,
                onRatingChanged: (rating) {
                  setState(() {
                    _overallRating = rating;
                  });
                  _updateOverallFromAspects();
                },
                size: 40,
              ),
            ),
            if (_overallRating > 0) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _getRatingDescription(_overallRating),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _getRatingColor(_overallRating),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAspectRatingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Ratings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rate different aspects of the service',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AspectRatingsWidget(
              aspectRatings: _aspectRatings,
              isEditable: true,
              onRatingChanged: (aspect, rating) {
                setState(() {
                  _aspectRatings[aspect] = rating;
                });
                _updateOverallFromAspects();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Your Experience',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell others about your experience (optional)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Describe your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              onChanged: (value) {
                setState(() {
                  _comment = value;
                });
              },
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Comment cannot exceed 500 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Tags',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select tags that describe your experience',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Photos (Optional)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share photos to support your review',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Add Photos'),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedPhotos.length}/3 photos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (_selectedPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedPhotos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, size: 32),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Post anonymously'),
              subtitle: const Text('Your name won\'t be visible to other users'),
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummary() {
    if (_overallRating == 0.0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: _getRatingColor(_overallRating),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_overallRating.toStringAsFixed(1)} out of 5',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getRatingColor(_overallRating),
                  ),
                ),
                const Spacer(),
                Text(
                  _getRatingDescription(_overallRating),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (_selectedTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tags: ${_selectedTags.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _overallRating > 0.0 && !_isSubmitting;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitReview : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.existingReview != null ? 'Update Review' : 'Submit Review',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Helper Methods
  void _updateOverallFromAspects() {
    final nonZeroRatings = _aspectRatings.values.where((rating) => rating > 0);
    if (nonZeroRatings.isNotEmpty && _overallRating == 0.0) {
      final average = nonZeroRatings.reduce((a, b) => a + b) / nonZeroRatings.length;
      setState(() {
        _overallRating = double.parse(average.toStringAsFixed(1));
      });
    }
  }

  void _pickPhotos() {
    // TODO: Implement photo picker
    if (_selectedPhotos.length < 3) {
      setState(() {
        _selectedPhotos.add('photo_${_selectedPhotos.length + 1}');
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
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

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate() || _overallRating == 0.0) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final reviewService = Provider.of<ReviewService>(context, listen: false);

      // Add overall rating to aspect ratings
      final finalAspectRatings = Map<ServiceAspect, double>.from(_aspectRatings);
      finalAspectRatings[ServiceAspect.overall] = _overallRating;

      final rating = BusServiceRating(
        id: widget.existingReview?.id ?? '',
        userId: user.uid,
        userName: _isAnonymous ? 'Anonymous' : (user.displayName ?? 'User'),
        userAvatar: user.photoURL ?? '',
        busNumber: _getServiceDisplayName(), // Use service display name
        routeId: widget.serviceId, // Use service ID as route ID for now
        routeName: _getServiceDisplayName(),
        driverId: '', // Empty for non-driver reviews
        serviceId: widget.serviceId,
        reviewType: widget.reviewType,
        overallRating: _overallRating,
        aspectRatings: finalAspectRatings,
        comment: _comment.trim(),
        reviewTitle: _getReviewTitle(),
        reviewText: _comment.trim(),
        tags: _selectedTags.toList(),
        photos: _selectedPhotos,
        journeyDate: DateTime.now(),
        reviewDate: DateTime.now(),
        journeyTime: TimeOfDay.now().format(context),
        boardingPoint: 'Unknown', // TODO: Get from location
        alightingPoint: 'Unknown', // TODO: Get from location
        isAnonymous: _isAnonymous,
        isVerifiedJourney: true, // TODO: Implement verification logic
        isVerified: true, // TODO: Implement verification logic
        createdAt: widget.existingReview?.createdAt ?? DateTime.now(),
        hasResponse: widget.existingReview?.hasResponse ?? false,
        helpfulVotes: widget.existingReview?.helpfulVotes ?? 0,
        totalVotes: widget.existingReview?.totalVotes ?? 0,
        reportedBy: const [],
        isModerated: false,
        moderationNote: null,
      );

      if (widget.existingReview != null) {
        await reviewService.updateReview(rating);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review updated successfully!')),
          );
        }
      } else {
        await reviewService.submitReview(rating);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted successfully!')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _deleteReview,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview() async {
    Navigator.of(context).pop(); // Close dialog

    try {
      final reviewService = Provider.of<ReviewService>(context, listen: false);
      await reviewService.deleteReview(widget.existingReview!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting review: $e')),
        );
      }
    }
  }

  String _getServiceDisplayName() {
    return widget.serviceName ?? widget.serviceId;
  }

  String _getReviewTitle() {
    final serviceName = _getServiceDisplayName();
    final ratingText = _overallRating >= 4.0 ? 'Great' : _overallRating >= 3.0 ? 'Good' : _overallRating >= 2.0 ? 'Average' : 'Poor';
    return '$ratingText experience with $serviceName';
  }
}