import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../models/activity_script.dart';
import '../providers/avatar_provider.dart';
import '../widgets/gradient_button.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  List<ActivityScript> _activities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    setState(() {
      _activities = ActivityScript.sampleActivities;
    });
  }

  Future<void> _completeActivity(ActivityScript activity) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add experience to each target power
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                return _buildActivityCard(activity);
              },
            ),
    );
  }

  Widget _buildActivityCard(ActivityScript activity) {
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
                    color: _getDifficultyColor(activity.difficulty).withOpacity(0.1),
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
                    color: color!.withOpacity(0.1),
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
        color: AppConstants.textSecondaryColor.withOpacity(0.1),
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