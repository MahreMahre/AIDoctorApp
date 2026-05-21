import 'package:flutter/material.dart';

/// Model class representing a Banner Card
class BannerModel {
  final String text;
  final List<Color> cardBackground;
  final String image;

  BannerModel({
    required this.text,
    required this.cardBackground,
    required this.image,
  }) {
    // Validate background list
    assert(cardBackground.length >= 2, 'cardBackground must have at least 2 colors');
  }
}

/// Sample banner card data
final List<BannerModel> bannerCards = [
  BannerModel(
    text: "Check Disease",
    cardBackground: [
      const Color(0xffa1d4ed),
      const Color(0xffc0eaff),
    ],
    image: "assets/images/414-bg.png",
  ),
  BannerModel(
    text: "Covid-19",
    cardBackground: [
      const Color(0xffb6d4fa),
      const Color(0xffcfe3fc),
    ],
    image: "assets/images/covid-bg.png",
  ),
];
