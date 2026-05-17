import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingConfirmationPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = booking['id'];
    final amount = booking['total_amount'];
    final date = booking['appointment_date'];
    final time = booking['appointment_time'];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Animation or Icon
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reference ID: #$id',
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _row(Icons.calendar_today, 'Date', date),
                    const Divider(height: 24, color: Colors.white10),
                    _row(Icons.access_time, 'Time', time),
                    const Divider(height: 24, color: Colors.white10),
                    _row(Icons.currency_rupee, 'To Pay', '₹$amount'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pay cash when you visit the shop',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/bookings'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                  child: const Text('View Booking History'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
