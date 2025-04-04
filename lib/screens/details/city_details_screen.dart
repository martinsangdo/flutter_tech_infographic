import 'package:ai_travel_planner/components/expandable_widget.dart';
import 'package:ai_travel_planner/components/percentage_display.dart';
import 'package:ai_travel_planner/db/city_model.dart';
import 'package:ai_travel_planner/db/database_helper.dart';
import 'package:ai_travel_planner/functions.dart';
import 'package:ai_travel_planner/screens/orderDetails/components/price_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../constants.dart';
import 'components/tab_items.dart';
import 'components/attraction_info.dart';
import 'package:http/http.dart' as http;

//display results after using AI planner
class CityDetailsScreen extends StatefulWidget {
  Map<dynamic, dynamic> cityInfo = {};
  Map<String, dynamic> cityOptions = {};  //options to create new trip 

  CityDetailsScreen({super.key, required this.cityInfo, required this.cityOptions});

  @override
  State<CityDetailsScreen> createState() =>
      _State();
}

class _State extends State<CityDetailsScreen> {
  Map<String, dynamic> _cityDetails = {};  //will fetch data into this later
  bool _isLoading = true; //loading the page
  Map _budgets = {};
  List _hotelList = [];
  //
    List _attractionList = [];
    List _restaurantList = [];

  //call to get details of city
  _fetchRawCityDetails(wonder_trip_id) async {
    String rawTripDetailsUrl = glb_wonder_uri + 'v4/plan/' + wonder_trip_id + '/__data.json';
    final response = await http.Client().post(Uri.parse(rawTripDetailsUrl), 
        headers: COMMON_HEADER);
    if (response.statusCode != 200){
      debugPrint('Cannot get content from cloud');
    } else {
      Map<String, dynamic> objFromCloud = jsonDecode(response.body);
      if (objFromCloud['nodes'] != null){
        //debugPrint(objFromCloud['nodes'][1]['data'].toString());
        Map<String, dynamic> parsedData = await parseRawTripDetails(objFromCloud['nodes'][1]['data']);
        if (parsedData['hotelList'] != null){
          //we had data of this city, save it details in state
          setState((){
            _cityDetails = parsedData;
            //debugPrint(parsedData.toString());
            if (_cityDetails['budgets'] != null){
              _budgets = _cityDetails['budgets'];
            }
            if (_cityDetails['hotelList'] != null){
              _hotelList = _cityDetails['hotelList'];
            }
            // if (_cityDetails['attractions'] != null){
            //   _attractionList = _cityDetails['attractions'];
            // }
            // debugPrint(_attractionList.toString());
            _isLoading = false;
          });
        } else {
          //why no day results? -> create trip & get data so fast
          setState(() {
            _isLoading = false;
          });
        }
        //get attractions from trip
        Map what2DoNEat = await _searchAttractionsInTrip();
        setState(() {
          _attractionList = what2DoNEat['whats2DoList'];
          _restaurantList = what2DoNEat['whats2EatList'];
        });
      }
      return {'result': 'OK', 'id': objFromCloud['id']};
    }
  }
  //get list of attractions in trip
_searchAttractionsInTrip() async{
  Map finalList = { //response those info
    'whats2DoList' : [],
    'whats2EatList' : []
  };
  String cityActivities = glb_trip_uri + GET_THINGS_2_EAT_N_VISIT;
  final response = await http.Client().post(Uri.parse(cityActivities), 
        headers: COMMON_HEADER, body: jsonEncode({
            "districtId": widget.cityInfo['city_id'],
            "moduleList": [
                "classicRecommendSight",
                "classicRecommendRestaurant"
            ],
            "head": {
                "locale": "en-US",
                "extension": [
                    {
                        "name": "locale",
                        "value": "en-US"
                    },
                    {
                        "name": "platform",
                        "value": "Online"
                    },
                    {
                        "name": "currency",
                        "value": "USD"
                    },
                    {
                        "name": "user-agent",
                        "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"
                    }
                ]
            }
        }));
    if (response.statusCode != 200){
      debugPrint('Cannot get content from cloud');
    } else {
      Map<String, dynamic> objFromCloud = jsonDecode(response.body);
      if (objFromCloud['moduleList'] != null){
        // debugPrint(objFromCloud['moduleList'][0].toString());
        if (objFromCloud['moduleList'][0]['typeName'] == 'classicRecommendSight'){
          //this is the list of whats to do
          try {
            List whats2Do = objFromCloud['moduleList'][0]['classicRecommendSightModule']['sightList'][0]['sightList'];
            for (Map what2Do in whats2Do){
              finalList['whats2DoList'].add({
                'trip_id': what2Do["id"],
                'name': what2Do["name"],
                'description': '',
                'image': what2Do["imageUrl"],
                'duration': 0,
                'commentNum': formatNumberWithCommas(what2Do['commentNum']!=null?int.parse(what2Do['commentNum']):0)
              });
            }
          } catch (e){
            debugPrint('Error when parse data what to do');
          }
        }
        if (objFromCloud['moduleList'][1]['typeName'] == 'classicRecommendRestaurant'){
          //this is a list of restaurants
          try {
            List whats2Eat = objFromCloud['moduleList'][1]['classicRecommendRestaurantModule']['restaurantList'][0]['restaurantList'];
            //debugPrint(whats2Eat.toString());
            for (Map what2Eat in whats2Eat){
              finalList['whats2EatList'].add({
                'trip_id': what2Eat["poiId"],
                'name': what2Eat["name"],
                'description': '',
                'image': what2Eat["imageUrl"],
                'duration': 0,
                'commentNum': formatNumberWithCommas(what2Eat['commentNum']!=null?int.parse(what2Eat['commentNum']):0)
              });
            }
          } catch (e){
            debugPrint('Error when parse data what to eat');
          }
        } 
      }
    }
  //debugPrint(finalList.toString());
  return finalList;
}
  //the travel date is expired if it happened before TODAY
  _isExpiredTravelDate(travelDate){
    if (travelDate.isNotEmpty){
      try {
        // 1. Parse the date string:
        DateFormat formatter = DateFormat(APP_DATE_FORMAT);
        DateTime date = formatter.parse(travelDate);
        // 2. Get today's date (at midnight):
        DateTime today = DateTime.now();
        DateTime todayMidnight = DateTime(today.year, today.month, today.day);
        // 3. Compare the dates:
        return date.isBefore(todayMidnight);
      } catch (e) {
        return true; //consider it is expired
      }
    } else {
      return true;  //empty means expired
    }
  }
  //generate new trip id and cache it
  _generateNewTripID() async{
    final headers = {'Content-Type': 'application/json'}; // Important for JSON requests
    //generate new trip
    String todayISO = getTomorrowFormatted();
    if (!todayISO.contains("Z")){
      todayISO += "Z";
    }
    Map requestBody = {
          "destinationDestinationId": widget.cityInfo['wonder_id'],
          "travelAt": widget.cityOptions!['travelAt']??todayISO,
          "days": DEFAULT_DURATION_DAYS,
          "budgetType": widget.cityOptions!['budgetType']??2,  //medium
          "groupType": widget.cityOptions!['groupType']??0, //solo
          "activityTypes": widget.cityOptions!['activityTypes']??[
            0, 1, 2, 3, 4, 5, 6, 7 //all activities
          ],
          "isVegan": false,
          "isHalal": false
        };
    // debugPrint('----------- generate new trip');
    // debugPrint(requestBody.toString());
    //
    final response = await http.Client().post(Uri.parse(glb_wonder_uri + GENERATE_NEW_TRIP_PLANNER), 
        headers: headers, body: jsonEncode(requestBody));
    if (response.statusCode != 200){
      return {'result': 'FAILED', 'message': 'Cannot create trip ID'};
    } else {
      Map<String, dynamic> objFromCloud = jsonDecode(response.body);
      if (objFromCloud['id'] != null){
        //debugPrint('Generated new trip id: ' + objFromCloud['id']);
        //generated successully
        //cache the date and trip id to db
        City newCityInfo = City.fromMap(widget.cityInfo);
        newCityInfo.travel_date = formatDateForUI(todayISO);
        newCityInfo.wonder_trip_id = objFromCloud['id'];
        DatabaseHelper.instance.updateCitydata(newCityInfo).then((id) async {
          //need to wait some minutes for Wonder gerating new data of trip, otherwise some info is null while getting the details
          await Future.delayed(const Duration(seconds: WAIT_TIME_NEW_TRIP));  //delay 15 secs
          _fetchRawCityDetails(objFromCloud['id']);
          return {'result': 'OK', 'id': objFromCloud['id']};
        });
      } else {
        //something wrong
        return {'result': 'FAILED', 'message': 'Cannot create trip ID'};
      }
    }
  }
  //save travel date and new trip ID to our local db
  _checkNGenerateTripID() async{
    //debugPrint(widget.cityInfo.toString());
    if (widget.cityInfo.isNotEmpty && widget.cityInfo['wonder_trip_id'].isNotEmpty){
      _checkExpiredTravelDate(widget.cityInfo['travel_date'], widget.cityInfo['wonder_trip_id']);
    } else {
      //check if this city existed in db or not, because this city may generated trip id before but not updated to homepage
      final dbData = await DatabaseHelper.instance.rawQuery("SELECT * FROM tb_city WHERE uuid='"+widget.cityInfo['uuid']+"'", []);
      if (dbData.isNotEmpty){
        if (dbData[0]['wonder_trip_id'].isNotEmpty){
          //this city had wonder trip id
          _checkExpiredTravelDate(dbData[0]['travel_date'], dbData[0]['wonder_trip_id']);
        } else {
          _generateNewTripID();
        }
      } else {
        //this case never happens
        debugPrint('_checkNGenerateTripID 111');
      }
    }
  }
  //
  _checkExpiredTravelDate(travelDate, wonder_trip_id){
    //check cache date to avoid generating so many trip in 1 date
      if (_isExpiredTravelDate(travelDate)){
        //debugPrint('_isExpiredTravelDate: ' + travelDate);
        _generateNewTripID();
      } else {
        //get data based on old trip (existing wonder trip id)
        //debugPrint('Old trip id: ' + wonder_trip_id);
        _fetchRawCityDetails(wonder_trip_id);
      }
  }
  //
  @override
  void initState() {
    super.initState();
    //debugPrint('Receiving city from homepage: ' + widget.cityInfo['name']);
    _checkNGenerateTripID();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(5),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading)
                      PercentageDisplay(duration: 120),
                    Text(
                      _cityDetails['locationName']??(widget.cityInfo['name']??''),
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                    ),
                    const SizedBox(height: defaultPadding),
                    Row(
                      children: [
                        DeliveryInfo(
                          iconSrc: "assets/icons/delivery.svg",
                          text: _cityDetails['currency_detail']??'...'
                        ),
                        const SizedBox(width: defaultPadding),
                        DeliveryInfo(
                          iconSrc: "assets/icons/fast-delivery.svg",
                          text: _cityDetails['travelDate']??'Generating suggestions ...',
                        ),
                      ],
                    ),
                    /*
                    OutlinedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Save"),
                        ),*/
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),
              //description
              Padding(padding: const EdgeInsets.all(defaultPadding / 2),
                child: Column(children: [
                  Text(
                    _cityDetails['description']??'',
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
                ),
              ),
              //history
              Padding(padding: const EdgeInsets.all(defaultPadding / 2),
                child: Column(children: [
                  Text(
                    _cityDetails['history']??'',
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
                ),
              ),
              //Budgets
              if (_budgets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(defaultPadding/2),
                  child:
                    Text(
                      "Budgets",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                ),
              const SizedBox(height: defaultPadding / 2),
              for (String budgetKey in _budgets.keys.toList())...[
                ExpandableWidget(
                  initialExpanded: true, // Set to true if you want it expanded initially
                  header: Container(
                    padding: const EdgeInsets.all(defaultPadding / 2),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(155, 194, 222, 162),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          budgetKey.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(color: Colors.black),
                        ),
                        const Icon(Icons.arrow_downward, color: Colors.white), // or use an animated icon
                      ],
                    ),
                  ),
                  content: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: Column(
                      children: [
                        for (Map budgetInfo in _budgets[budgetKey]) ...[
                          PriceRow(text: budgetInfo['type'], price: budgetInfo['priceUsd']),
                          const SizedBox(height: defaultPadding / 2),
                        ],
                      ]
                    ),
                  ),
                ),
              const SizedBox(height: defaultPadding / 2),
              ],
              //including tabs inside
              TabItems(hotelList: _hotelList, attractions: _attractionList, restaurants: _restaurantList),
              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
