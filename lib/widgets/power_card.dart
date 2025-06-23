import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/power.dart';

class PowerCard extends StatelessWidget {
  final Power power;
  final VoidCallback? onTap;

  const PowerCard({
    super.key,
    required this.power,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.powerColors[power.type.toString().split('.').last];

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                    ),
                    child: Center(
                      child: Text(
                        power.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          power.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: color,
                          ),
                        ),
                        Text(
                          'Level ${power.level}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS,
                      vertical: AppConstants.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                    ),
                    child: Text(
                      '${power.experience}/${power.experienceToNextLevel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                power.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                      Text(
                        '${(power.progressPercentage * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  LinearProgressIndicator(
                    value: power.progressPercentage,
                    backgroundColor: AppConstants.textSecondaryColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ],
              ),
              if (power.achievements.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Wrap(
                  spacing: AppConstants.spacingXS,
                  runSpacing: AppConstants.spacingXS,
                  children: power.achievements.take(3).map((achievement) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingS,
                        vertical: AppConstants.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                      ),
                      child: Text(
                        achievement,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (power.achievements.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: AppConstants.spacingXS),
                    child: Text(
                      '+${power.achievements.length - 3} more',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.textSecondaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 