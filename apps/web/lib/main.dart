// Habitat Web Command & Analytics Center (Flutter Web)
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HabitatWebCommandApp());
}

class HabitatWebCommandApp extends StatelessWidget {
  const HabitatWebCommandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitat Command Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0C),
        primaryColor: const Color(0xFFFF9500),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9500),
          secondary: Color(0xFFFF3B30),
          surface: Color(0xFF141419),
        ),
      ),
      home: const WebDashboardScreen(),
    );
  }
}

class WebDashboardScreen extends StatelessWidget {
  const WebDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: Row(
        children: [
          // 1. Left Sidebar Navigation
          _buildSidebar(),

          // 2. Main Content Dashboard
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildMetricsRow(),
                  const SizedBox(height: 32),
                  _buildResistanceHeatmapSection(),
                  const SizedBox(height: 32),
                  _buildAuditLedgerAndMissionsRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF101014),
        border: Border(right: BorderSide(color: Color(0xFF22222A))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield, color: Color(0xFFFF9500), size: 28),
              SizedBox(width: 10),
              Text(
                'HABITAT',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 36),
          _buildNavTile(Icons.dashboard, 'Command Overview', true),
          _buildNavTile(Icons.alarm, 'Mission Protocols', false),
          _buildNavTile(Icons.show_chart, 'Resistance Analytics', false),
          _buildNavTile(Icons.receipt_long, 'XP Audit Ledger', false),
          _buildNavTile(Icons.inventory_2_outlined, 'Task Catalog', false),
          const Spacer(),
          _buildNavTile(Icons.settings_outlined, 'Settings', false),
        ],
      ),
    );
  }

  Widget _buildNavTile(IconData icon, String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E1E26) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isActive ? const Color(0xFFFF9500) : const Color(0xFF8E8E93)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF8E8E93),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COMMAND OVERVIEW', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            SizedBox(height: 4),
            Text('Good Morning, Alex Mercer', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          ],
        ),
        Chip(
          backgroundColor: Color(0xFF1C1C24),
          label: Text('⚡ LIVE SYNC ACTIVE', style: TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return const Row(
      children: [
        Expanded(child: _MetricCard(title: 'DISCIPLINE SCORE', value: '85 / 100', subtitle: '▲ +4% from last week', accentColor: Color(0xFF34C759))),
        SizedBox(width: 16),
        Expanded(child: _MetricCard(title: 'STREAK STATUS', value: '🔥 12 DAYS', subtitle: '1 Grace Token in Vault', accentColor: Color(0xFFFF3B30))),
        SizedBox(width: 16),
        Expanded(child: _MetricCard(title: 'AVG RESISTANCE (ΔtR)', value: '1.8 MIN', subtitle: 'Elite Instant Action Tier', accentColor: Color(0xFFFF9500))),
        SizedBox(width: 16),
        Expanded(child: _MetricCard(title: 'TOTAL XP LEDGER', value: '2,450 XP', subtitle: 'Level 5 Habit Master', accentColor: Color(0xFF0A84FF))),
      ],
    );
  }

  Widget _buildResistanceHeatmapSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22222A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEEKLY RESISTANCE TRENDS (ΔtR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('Target: < 2.0m', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _HeatmapDayBar(day: 'Mon', minutes: 1.5, isGoal: true),
              _HeatmapDayBar(day: 'Tue', minutes: 2.1, isGoal: true),
              _HeatmapDayBar(day: 'Wed', minutes: 4.8, isGoal: false),
              _HeatmapDayBar(day: 'Thu', minutes: 1.2, isGoal: true),
              _HeatmapDayBar(day: 'Fri', minutes: 1.8, isGoal: true),
              _HeatmapDayBar(day: 'Sat', minutes: 3.0, isGoal: false),
              _HeatmapDayBar(day: 'Sun', minutes: 1.4, isGoal: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLedgerAndMissionsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today's Missions
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141419),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF22222A)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TODAY'S MISSION PROTOCOLS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 16),
                _MissionRow(time: '07:00 AM', title: 'Make Your Bed', status: 'VERIFIED', isDone: true),
                _MissionRow(time: '08:30 AM', title: '10 Morning Push-Ups', status: 'COMPLETED', isDone: true),
                _MissionRow(time: '10:30 PM', title: 'Prepare Tomorrow Clothes', status: 'PENDING', isDone: false),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // XP Audit Ledger
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141419),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF22222A)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("XP TRANSACTION AUDIT LEDGER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 16),
                _LedgerRow(reason: 'Mission: Make Bed', amount: '+50 XP', time: 'Today 07:02'),
                _LedgerRow(reason: 'First Attempt Speed Bonus', amount: '+25 XP', time: 'Today 07:02'),
                _LedgerRow(reason: 'Mission: 10 Push-Ups', amount: '+80 XP', time: 'Today 08:31'),
                _LedgerRow(reason: 'Welcome Onboarding Bonus', amount: '+100 XP', time: 'Aug 26'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  const _MetricCard({required this.title, required this.value, required this.subtitle, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22222A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
        ],
      ),
    );
  }
}

class _HeatmapDayBar extends StatelessWidget {
  final String day;
  final double minutes;
  final bool isGoal;

  const _HeatmapDayBar({required this.day, required this.minutes, required this.isGoal});

  @override
  Widget build(BuildContext context) {
    final height = (minutes * 20).clamp(20.0, 120.0);
    return Column(
      children: [
        Text('${minutes.toStringAsFixed(1)}m', style: TextStyle(color: isGoal ? const Color(0xFF34C759) : const Color(0xFFFF9500), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: height,
          decoration: BoxDecoration(
            color: isGoal ? const Color(0xFF34C759).withOpacity(0.3) : const Color(0xFFFF9500).withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isGoal ? const Color(0xFF34C759) : const Color(0xFFFF9500)),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
      ],
    );
  }
}

class _MissionRow extends StatelessWidget {
  final String time;
  final String title;
  final String status;
  final bool isDone;

  const _MissionRow({required this.time, required this.title, required this.status, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isDone ? Icons.check_circle : Icons.schedule, size: 16, color: isDone ? const Color(0xFF34C759) : const Color(0xFF8E8E93)),
              const SizedBox(width: 8),
              Text('$time — $title', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(status, style: TextStyle(color: isDone ? const Color(0xFF34C759) : const Color(0xFFFF9500), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final String reason;
  final String amount;
  final String time;

  const _LedgerRow({required this.reason, required this.amount, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(time, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
            ],
          ),
          Text(amount, style: const TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
