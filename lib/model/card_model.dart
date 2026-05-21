import 'package:flutter/material.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// A model representing a medical card (e.g. doctor type)
class CardModel {
  final String title;
  final Color backgroundColor;
  final IconData icon;

  CardModel({
    required this.title,
    required this.backgroundColor,
    required this.icon,
  });
}

/// List of card data
final List<CardModel> cards = [
  CardModel(
    title: "Cardiologist",
    backgroundColor: const Color(0xFFec407a),
    icon: Icons.heart_broken,
  ),
  CardModel(
    title: "Dentist",
    backgroundColor: const Color(0xFF5c6bc0),
    icon: Icons.medical_services, // fallback: tooth icon not natively supported
  ),
  CardModel(
    title: "Eye Specialist",
    backgroundColor: const Color(0xFFfbc02d),
    icon: TablerIcons.eye,
  ),
  CardModel(
    title: "Orthopaedic",
    backgroundColor: const Color(0xFF1565C0),
    icon: Icons.wheelchair_pickup_sharp,
  ),
  CardModel(
    title: "Paediatrician",
    backgroundColor: const Color(0xFF2E7D32),
    icon: Icons.child_care, // Unicode 🧶 not recommended, replaced with standard icon
  ),
];
