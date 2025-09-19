import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/app_theme.dart';
import '../data/user_manual_content.dart';

class UserManualScreen extends StatefulWidget {
  const UserManualScreen({Key? key}) : super(key: key);

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedSection;
  Set<String> _bookmarkedSections = {};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<MapEntry<String, ManualSection>> _getFilteredSections() {
    final sections = UserManualContent.sections.entries.toList();
    
    if (_searchQuery.isEmpty) {
      return sections;
    }
    
    return sections.where((entry) {
      final section = entry.value;
      final query = _searchQuery.toLowerCase();
      
      // Search in section title
      if (section.title.toLowerCase().contains(query)) {
        return true;
      }
      
      // Search in subsection titles and content
      for (final subsection in section.subsections) {
        if (subsection.title.toLowerCase().contains(query) ||
            subsection.content.toLowerCase().contains(query)) {
          return true;
        }
      }
      
      return false;
    }).toList();
  }

  void _toggleBookmark(String sectionKey) {
    setState(() {
      if (_bookmarkedSections.contains(sectionKey)) {
        _bookmarkedSections.remove(sectionKey);
      } else {
        _bookmarkedSections.add(sectionKey);
      }
    });
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _bookmarkedSections.contains(sectionKey) 
            ? 'Bookmarked!' 
            : 'Bookmark removed',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _scrollToSection(String sectionKey) {
    // Simple scroll to top for demo - could be enhanced with precise scrolling
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    setState(() {
      _selectedSection = sectionKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ThemedScaffold(
      title: 'User Manual',
      actions: [
        // Bookmarks button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.bookmark),
                if (_bookmarkedSections.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _bookmarkedSections.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showBookmarksDialog,
          ),
          
          // Table of contents
          IconButton(
            icon: const Icon(Icons.toc),
            onPressed: _showTableOfContents,
          ),
        ],
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: colorScheme.shadow.withOpacity(0.1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search user manual...',
                hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      
      // Floating action button for quick navigation
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickNavigation,
        child: const Icon(Icons.navigation),
        tooltip: 'Quick Navigation',
      ),
    );
  }

  Widget _buildContent() {
    final filteredSections = _getFilteredSections();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (filteredSections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colorScheme.onBackground.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18, 
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms',
              style: TextStyle(color: colorScheme.onBackground.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredSections.length,
      itemBuilder: (context, index) {
        final entry = filteredSections[index];
        final sectionKey = entry.key;
        final section = entry.value;
        final isSelected = _selectedSection == sectionKey;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isSelected 
              ? colorScheme.primaryContainer.withOpacity(0.3) 
              : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isSelected 
              ? Border.all(color: colorScheme.primary) 
              : Border.all(color: colorScheme.outline.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 2),
                blurRadius: 8,
                color: colorScheme.shadow.withOpacity(0.1),
              ),
            ],
          ),
          child: ExpansionTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  section.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              section.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _bookmarkedSections.contains(sectionKey)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                    color: _bookmarkedSections.contains(sectionKey)
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () => _toggleBookmark(sectionKey),
                ),
                Icon(Icons.expand_more, color: colorScheme.onSurface.withOpacity(0.6)),
              ],
            ),
            children: section.subsections.map((subsection) {
              return _buildSubsection(subsection);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSubsection(ManualSubsection subsection) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subsection.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: _buildFormattedContent(subsection.content),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      
      if (line.startsWith('# ') || line.startsWith('## ')) {
        // Heading
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              line.replaceAll(RegExp(r'^#+\s*'), ''),
              style: TextStyle(
                fontSize: line.startsWith('# ') ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        );
      } else if (line.startsWith('**') && line.endsWith('**')) {
        // Bold text
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line.replaceAll('**', ''),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        // Bullet point
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
                Expanded(
                  child: Text(
                    line.replaceAll(RegExp(r'^[-•]\s*'), ''),
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('```')) {
        // Code block - skip for now
        continue;
      } else if (line.contains('❌') || line.contains('✅') || line.contains('→')) {
        // Special formatted lines
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: line.contains('❌') 
                ? colorScheme.error.withOpacity(0.1)
                : line.contains('✅')
                  ? colorScheme.primary.withOpacity(0.1)
                  : colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              line,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
          ),
        );
      } else {
        // Regular text
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 14, 
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bookmarked Sections'),
        content: _bookmarkedSections.isEmpty
          ? const Text('No bookmarks yet.\n\nTap the bookmark icon next to any section to save it for quick access.')
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _bookmarkedSections.length,
                itemBuilder: (context, index) {
                  final sectionKey = _bookmarkedSections.elementAt(index);
                  final section = UserManualContent.sections[sectionKey];
                  
                  return ListTile(
                    leading: Text(section?.icon ?? '📖'),
                    title: Text(section?.title ?? sectionKey),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_remove),
                      onPressed: () {
                        _toggleBookmark(sectionKey);
                        Navigator.of(context).pop();
                        _showBookmarksDialog(); // Refresh dialog
                      },
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _scrollToSection(sectionKey);
                    },
                  );
                },
              ),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Table of Contents',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: UserManualContent.sections.length,
                itemBuilder: (context, index) {
                  final entry = UserManualContent.sections.entries.elementAt(index);
                  final sectionKey = entry.key;
                  final section = entry.value;
                  
                  return ListTile(
                    leading: Text(section.icon, style: const TextStyle(fontSize: 24)),
                    title: Text(section.title),
                    subtitle: Text('${section.subsections.length} topics'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _scrollToSection(sectionKey);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickNavigation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickNavButton(
                  icon: Icons.rocket_launch,
                  label: 'Getting Started',
                  onTap: () {
                    Navigator.of(context).pop();
                    _scrollToSection('getting_started');
                  },
                ),
                _buildQuickNavButton(
                  icon: Icons.confirmation_num,
                  label: 'Book Ticket',
                  onTap: () {
                    Navigator.of(context).pop();
                    _scrollToSection('ticket_booking');
                  },
                ),
                _buildQuickNavButton(
                  icon: Icons.mic,
                  label: 'Voice Help',
                  onTap: () {
                    Navigator.of(context).pop();
                    _scrollToSection('voice_features');
                  },
                ),
                _buildQuickNavButton(
                  icon: Icons.help_outline,
                  label: 'Troubleshoot',
                  onTap: () {
                    Navigator.of(context).pop();
                    _scrollToSection('troubleshooting');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}