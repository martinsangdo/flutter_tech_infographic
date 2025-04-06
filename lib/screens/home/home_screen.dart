import 'dart:convert';

import 'package:techfact_infographic/components/percentage_display.dart';
import 'package:techfact_infographic/db/database_helper.dart';
import 'package:flutter/material.dart';

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
        title: Center(
          child: Column(
            children: [
              Text(
                "Explore".toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: primaryColor),
              ),
              const Text(
                "Top destinations",
                style: TextStyle(color: Colors.black),
              )
            ],
          )
        )
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.all(5),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                PercentageDisplay(duration: 100,),
                
              ],
            ],
          ),
        ),
      ),
    );
  }
}
