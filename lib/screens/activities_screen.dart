import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../models/activity_script.dart';
import '../providers/avatar_provider.dart';
import '../providers/activities_provider.dart';
import '../services/blockchain_service.dart';
import '../widgets/gradient_button.dart';
import 'activity_authoring_screen.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh activities when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activitiesProvider.notifier).refresh();
    });
  }

  Future<void> _completeActivity(ActivityScript activity) async {
    final avatar = ref.read(avatarProvider);
    if (avatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an avatar first'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    try {
      final blockchainService = BlockchainService();
      
      // Complete activity on blockchain
      await blockchainService.completeActivity(
        activityId: activity.id,
        avatarId: avatar.id,
        proof: '',
      );

      // Add experience to each target power locally
      for (final powerType in activity.targetPowers) {
        await ref.read(avatarProvider.notifier).addExperienceToPower(
          powerType,
          activity.experienceReward ~/ activity.targetPowers.length,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity completed! +${activity.experienceReward} XP'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        
        // Refresh activities to update completion status
        ref.read(activitiesProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete activity: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider);
    final canCreate = ref.watch(canCreateActivityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          // Show create button only if user can create activities
          canCreate.when(
            data: (canCreate) => canCreate
                ? IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Author Activity',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ActivityAuthoringScreen(),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(activitiesProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement activity search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement activity filtering
            },
          ),
        ],
      ),
      body: activitiesAsync.when(
        data: (activities) {
          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: AppConstants.textSecondaryColor,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'No activities found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    'Activities will appear here once they are created on the blockchain',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(activitiesProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityCard(activity);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppConstants.errorColor,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'Error loading activities',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConstants.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingM),
              ElevatedButton(
                onPressed: () {
                  ref.read(activitiesProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityScript activity) {
    final activityTypeString = activity.activityType.toString().split('.').last;
    final activityTypeColor = AppConstants.activityTypeColors[activityTypeString] ?? AppConstants.primaryColor;
    final activityTypeIcon = AppConstants.activityTypeIcons[activityTypeString] ?? '📝';
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(activity.difficulty).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                  ),
                  child: Text(
                    activity.difficultyLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getDifficultyColor(activity.difficulty),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingS),
            
            // Activity Type Badge (Goldfire Phase 1)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingXS,
              ),
              decoration: BoxDecoration(
                color: activityTypeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(activityTypeIcon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: AppConstants.spacingXS),
                  Text(
                    activity.activityTypeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: activityTypeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingS),
            
            Text(
              activity.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Target Powers
            Wrap(
              spacing: AppConstants.spacingS,
              children: activity.targetPowers.map((powerType) {
                final color = AppConstants.powerColors[powerType.toString().split('.').last];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: color!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                  ),
                  child: Text(
                    powerType.toString().split('.').last.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Activity Details
            Row(
              children: [
                _buildDetailChip(
                  Icons.access_time,
                  activity.durationLabel,
                ),
                const SizedBox(width: AppConstants.spacingS),
                _buildDetailChip(
                  Icons.flash_on,
                  '+${activity.experienceReward} XP',
                ),
                if (activity.isGroupActivity) ...[
                  const SizedBox(width: AppConstants.spacingS),
                  _buildDetailChip(
                    Icons.group,
                    'Group',
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Instructions (collapsible)
            ExpansionTile(
              title: Text(
                'Instructions',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Text(
                    activity.instructions,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Implement activity details view
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: GradientButton(
                    onPressed: () => _completeActivity(activity),
                    child: const Text('Complete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppConstants.textSecondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppConstants.textSecondaryColor,
          ),
          const SizedBox(width: AppConstants.spacingXS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(ActivityDifficulty difficulty) {
    switch (difficulty) {
      case ActivityDifficulty.beginner:
        return AppConstants.successColor;
      case ActivityDifficulty.intermediate:
        return AppConstants.warningColor;
      case ActivityDifficulty.advanced:
        return AppConstants.primaryColor;
      case ActivityDifficulty.expert:
        return AppConstants.errorColor;
    }
  }
} 