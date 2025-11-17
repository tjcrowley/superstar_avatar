import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../providers/avatar_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/power_card.dart';
import '../widgets/avatar_profile_card.dart';
import 'activities_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(avatarProvider);
    
    if (avatar == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildPowersTab(),
          const ActivitiesScreen(),
          _buildHouseTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on),
            label: 'Powers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'House',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final avatar = ref.watch(avatarProvider)!;
    final totalLevel = ref.watch(totalLevelProvider);
    final totalExperience = ref.watch(totalExperienceProvider);
    final isSuperstarAvatar = ref.watch(isSuperstarAvatarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Superstar Avatar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(avatarProvider.notifier).syncWithBlockchain();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Profile Card
              AvatarProfileCard(avatar: avatar),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Superstar Avatar Status
              if (isSuperstarAvatar)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    gradient: AppConstants.powerGradient,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                    boxShadow: AppConstants.shadowMedium,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      Expanded(
                        child: Text(
                          'Superstar Avatar',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Stats Overview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Total Level',
                              totalLevel.toString(),
                              Icons.trending_up,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Experience',
                              totalExperience.toString(),
                              Icons.flash_on,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 2; // Activities tab
                        });
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.assignment, color: Colors.white),
                          SizedBox(height: AppConstants.spacingXS),
                          Text('Find Activities'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: GradientButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 3; // House tab
                        });
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.group, color: Colors.white),
                          SizedBox(height: AppConstants.spacingXS),
                          Text('Join House'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildRecentActivityCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowersTab() {
    final powers = ref.watch(powersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Powers'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        itemCount: powers.length,
        itemBuilder: (context, index) {
          final power = powers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
            child: PowerCard(power: power),
          );
        },
      ),
    );
  }

  Widget _buildHouseTab() {
    final currentHouse = ref.watch(currentHouseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('House'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            if (currentHouse.id != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    children: [
                      Text(
                        currentHouse.name ?? 'Unknown House',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'You are a member of this house',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.group,
                        size: 48,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'Join a House',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'Connect with like-minded individuals and support each other\'s growth',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      GradientButton(
                        onPressed: () {
                          // TODO: Implement house selection
                        },
                        child: const Text('Browse Houses'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final avatar = ref.watch(avatarProvider)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            // Profile Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                      child: Text(
                        avatar.name[0].toUpperCase(),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    Text(
                      avatar.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (avatar.bio != null) ...[
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        avatar.bio!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppConstants.spacingM),
                    Text(
                      avatar.status,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Badges
            if (avatar.badges.isNotEmpty) ...[
              Text(
                'Badges',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Wrap(
                spacing: AppConstants.spacingS,
                runSpacing: AppConstants.spacingS,
                children: avatar.badges.map((badge) {
                  return Chip(
                    label: Text(badge),
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: AppConstants.primaryColor),
                  );
                }).toList(),
              ),
            ],
            
            const Spacer(),
            
            // Logout Button
            OutlinedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  await ref.read(avatarProvider.notifier).clearAvatar();
                }
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConstants.primaryColor,
          size: 24,
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppConstants.primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppConstants.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'No recent activity',
              style: TextStyle(
                color: AppConstants.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 