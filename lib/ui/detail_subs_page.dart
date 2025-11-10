import 'package:flutter/material.dart';

class MembershipPlanDetailPage extends StatefulWidget {
  const MembershipPlanDetailPage({Key? key}) : super(key: key);

  @override
  State<MembershipPlanDetailPage> createState() => _MembershipPlanDetailPageState();
}

class _MembershipPlanDetailPageState extends State<MembershipPlanDetailPage> {
  String selectedPlan = 'basic';
  String selectedFrequency = 'quarterly';

  final Map<String, dynamic> plans = {
    'basic': {
      'name': 'Basic Plan',
      'color': Colors.blue,
      'services': [
        'Brake adjustment and tightening',
        'Lubrication',
        'Screw tightening',
        'Chain adjustment and lubrication',
        'Air filter cleaning',
        'Engine oil (on MRP)'
      ],
      'pricing': {
        'quarterly': {'price': 499, 'visits': 1, 'duration': '3 months'},
        'halfYearly': {'price': 899, 'visits': 3, 'duration': '6 months'},
        'yearly': {'price': 1699, 'visits': 6, 'duration': '12 months'}
      },
      'discount': '10% off on labour charge for additional work'
    },
    'premium': {
      'name': 'Premium Plan',
      'color': Colors.purple,
      'services': [
        'Priority',
        'Break adjustment and tightening',
        'Lubrication',
        'Screw tightening',
        'Air filter cleaning',
        'Washing',
        'Polishing',
        'Engine oil (5% off on MRP)',
        'General bike inspection',
        'Chain lubrication and adjustment'
      ],
      'pricing': {
        'quarterly': {'price': 699, 'visits': 1, 'duration': '3 months'},
        'halfYearly': {'price': 1299, 'visits': 3, 'duration': '6 months'},
        'yearly': {'price': 2499, 'visits': 6, 'duration': '12 months'}
      },
      'discount': '15% off on labour charge on additional work'
    }
  };

  @override
  Widget build(BuildContext context) {
    final currentPlan = plans[selectedPlan]!;
    final currentPricing = currentPlan['pricing'][selectedFrequency];
    final Color planColor = currentPlan['color'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: planColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Membership Plans',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          selectedPlan == 'basic' ? Icons.build : Icons.star,
                          color: Colors.white,
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Plan Selector
                    Row(
                      children: [
                        Expanded(
                          child: _buildPlanButton('basic', 'Basic', Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPlanButton('premium', 'Premium', Colors.purple),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Pricing Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Starting from',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '₹${currentPricing['price']}',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '/${currentPricing['duration']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: planColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_month,
                                color: planColor,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Select Plan Duration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFrequencyButton('quarterly', planColor),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFrequencyButton('halfYearly', planColor),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFrequencyButton('yearly', planColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: planColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Max ${currentPricing['visits']} service${currentPricing['visits'] > 1 ? 's' : ''} in ${currentPricing['duration']}',
                              style: TextStyle(
                                color: planColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Services Included
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Services Included',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(
                          currentPlan['services'].length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: planColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    currentPlan['services'][index],
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Special Offer
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [planColor, planColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: planColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Special Offer!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentPlan['discount'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle subscription
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: planColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Subscribe Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanButton(String plan, String label, Color color) {
    final isSelected = selectedPlan == plan;
    return GestureDetector(
      onTap: () => setState(() => selectedPlan = plan),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyButton(String frequency, Color planColor) {
    final isSelected = selectedFrequency == frequency;
    final pricing = plans[selectedPlan]['pricing'][frequency];
    
    return GestureDetector(
      onTap: () => setState(() => selectedFrequency = frequency),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? planColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              pricing['duration'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '₹${pricing['price']}',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}