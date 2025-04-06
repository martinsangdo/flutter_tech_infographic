import 'dart:convert';

import 'package:techfact_infographic/components/percentage_display.dart';
import 'package:techfact_infographic/db/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:techfact_infographic/screens/featured/components/basic_image_cart.dart';

import '../../components/cards/big/info_big_card.dart';
import '../../components/section_title.dart';
import '../../constants.dart';
import 'components/medium_card_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  //
  List<String> _homeSliderImages = [];
  Map<dynamic, dynamic> _topBannerInfo = {};
  //
  List<String> _randomPickImages = [];
  Map<dynamic, dynamic> _randomPickInfo = {};

  final List<BasicImageCard> items = [
    BasicImageCard(
      imageUrl: SAMPLE_IMG_1,
      caption: 'First Item',
      dateTime: DateTime.now().subtract(Duration(hours: 2)),
    ),
    BasicImageCard(
      imageUrl: SAMPLE_IMG_2,
      caption: 'Second Item with a longer caption',
      dateTime: DateTime.now().subtract(Duration(days: 1)),
    ),
    BasicImageCard(
      imageUrl: 'https://via.placeholder.com/150/F44336/FFFFFF?Text=Image+3',
      caption: 'Third',
      dateTime: DateTime.now(),
    ),
    // Add more items as needed
  ];

  //
  @override
  void initState() {
      super.initState();
  } 

  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Column(
            children: [
              Text(
                "Tech Infographic",
                style: TextStyle(color: Colors.black),
              )
            ],
          )
        )
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Text('Failed to load image'),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    item.caption,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    '${item.dateTime.day}/${item.dateTime.month}/${item.dateTime.year} ${item.dateTime.hour}:${item.dateTime.minute}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
