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
  List<BasicImageCard> _items = [];
  int _currentPage = 1;
  final int _itemsPerPage = 3;
  //
  final ScrollController _scrollController = ScrollController();
  //
  @override
  void initState() {
      super.initState();
      _loadMoreItems();
      _scrollController.addListener(_scrollListener);

  } 

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading) {
        _loadMoreItems();
      }
    }
  }

  // Simulate loading more items from an API or data source
  _loadMoreItems() async {
    debugPrint('load more item ' + _currentPage.toString());
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    // Simulate a network delay
    await Future.delayed(Duration(seconds: 1));

    // Generate a new batch of items
    // List<BasicImageCard> newItems = List.generate(
    //   _itemsPerPage,
    //   (index) => BasicImageCard(
    //     imageUrl: SAMPLE_IMG_1,
    //     caption: 'Item ${_currentPage * _itemsPerPage + index + 1}',
    //     dateTime: DateTime.now().add(Duration(minutes: index)),
    //   ),
    // );
    List<BasicImageCard> newItems = [
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
        imageUrl: SAMPLE_IMG_1,
        caption: 'Third',
        dateTime: DateTime.now(),
      ),
      // Add more items as needed
    ];

    setState(() {
      _items.addAll(newItems);
      _currentPage++;
      _isLoading = false;
    });
    //
    // throw Exception("_loadMoreItems");
  }
  //
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
      backgroundColor: Colors.white, // Set the background color here
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            itemCount: _items.length + (_isLoading ? 1 : 0), // Add 1 for the loading indicator
            itemBuilder: (context, index) {
              if (index < _items.length) {
                final item = _items[index];
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
                      ],
                    ),
                  ),
                );
              } else if (_isLoading) {
                return const Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return SizedBox.shrink(); // Should not happen
            },
          ),
          // if (_isLoading && _items.isEmpty)
          //   Center(child: CircularProgressIndicator()), // Initial loading indicator
        ],
      ),
    );
  }
}
