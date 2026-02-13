import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/auth_provider.dart';

class StreakModal extends StatelessWidget {
  const StreakModal({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final streak = user?.streakCount ?? 0;
    final theme = Theme.of(context);

    // Mocking week days for visual purpose since we don't have detailed history yet
    final weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    // We'll just pretend the last 'streak' days are checked for the visual
    // In a real app, we'd map this to actual dates.
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fire Icon Wrapper
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 120,
                  color: Colors.orange.shade600,
                  shadows: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                Positioned(
                  top: 45,
                  child: Text(
                    '$streak',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'días de racha',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
            
            // Calendar Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays.map((day) {
                      // Simple logic: Highlight today and previous days based on streak count
                      // This is purely visual/mock for now as per "user wants the UI"
                      final isToday = day == 'Dom'; // Assuming today is Sunday for demo? Or just highlight 'Today'
                      // Let's just highlight the last few days physically in the list
                      // A better mock:
                      return Column(
                        children: [
                          Text(
                            day,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDayCircle(day, streak),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Tu racha muestra cuántos días seguidos has practicado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary, // App Theme Color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'CONTINUAR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCircle(String day, int streak) {
    // Logic to determine if a day should be highlighted based on the current weekday and streak.
    
    // 1. Map day string to weekday index (1 = Mon, 7 = Sun)
    final Map<String, int> dayToIndex = {
      'Lun': 1, 'Mar': 2, 'Mié': 3, 'Jue': 4, 'Vie': 5, 'Sáb': 6, 'Dom': 7
    };
    
    int dayIndex = dayToIndex[day]!;
    int todayIndex = DateTime.now().weekday; // 1 = Mon, ..., 7 = Sun
    
    // 2. Check conditions:
    // - The day must be today or before today (in the current week view).
    // - The day must be within the streak range counting backwards from today.
    //   e.g. Today=Fri(5), Streak=2. Active days: Fri(5), Thu(4).
    //   Indices: 5, 4. 
    //   Condition: (todayIndex - dayIndex) < streak
    
    bool isPastOrToday = dayIndex <= todayIndex;
    bool isWithinStreak = (todayIndex - dayIndex) < streak;
    
    bool isActive = isPastOrToday && isWithinStreak;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? Colors.amber : Colors.grey.shade200,
        shape: BoxShape.circle,
        border: isActive ? Border.all(color: Colors.amber.shade700, width: 2) : null,
      ),
      child: isActive
          ? const Icon(Icons.check, size: 20, color: Colors.white)
          : null,
    );
  }
}
