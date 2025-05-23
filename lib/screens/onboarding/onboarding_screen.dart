import 'dart:convert';

import 'package:techfact_infographic/db/database_helper.dart';
import 'package:techfact_infographic/db/metadata_model.dart';
import 'package:techfact_infographic/entry_point.dart';
import 'package:techfact_infographic/screens/home/home_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';

import 'components/onboard_content.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  //1. load metadata of project
    void fetchMetadata() async {
      final response = await http.Client().get(Uri.parse(METADATA_URL));
      if (response.statusCode != 200){
        debugPrint('Cannot get metadata from cloud');
        //display something or check if we had metadata in sqlite
        refreshMetaDataWithCloudData(MetaDataModel.empty(uuid: ""));
      } else {
        final metadataObjFromCloud = MetaDataModel.fromJson(jsonDecode(response.body));
        //Query db & compare with latest data from cloud
        refreshMetaDataWithCloudData(metadataObjFromCloud);
      }
    }
    //
  void refreshMetaDataWithCloudData(MetaDataModel metadataObjFromCloud) async{
    //check if table metadata existed
      final metadataInDB = await DatabaseHelper.instance.rawQuery('SELECT * FROM metadata', []);
        if (metadataInDB.isEmpty){
          //there is no metadata in db
          if (metadataObjFromCloud.uuid != ""){
            //insert new
            DatabaseHelper.instance.insertMetadata(metadataObjFromCloud).then((id){
              debugPrint('Inserted metadata into db');
              updateGlobalVariablesNMove2Home(metadataObjFromCloud, false);
            });
          } else {
            //todo: no data from db neither cloud -> should tell them to close app & try again
          }
        } else if (metadataObjFromCloud.uuid != ""){
          debugPrint('Metadata existed in db time: ${metadataInDB[0]['update_time']}');
          //compare update_time
          var updateTimeInDB =  metadataInDB[0]['update_time'];
          var updateTimeInCloud =  metadataObjFromCloud.update_time;
          if (updateTimeInDB != updateTimeInCloud){
            //update metadata in db
            DatabaseHelper.instance.updateMetadata(metadataObjFromCloud).then((id){
              debugPrint('Updated new metadata into db');
              updateGlobalVariablesNMove2Home(metadataObjFromCloud, false);
            });
          } else {
            //do nothing because there is no new info from cloud
            updateGlobalVariablesNMove2Home(metadataObjFromCloud, true);
          }
        } else {
          //do nothing because metadata existed in db & has nothing new from cloud
          updateGlobalVariablesNMove2Home(metadataInDB[0], true);
        }
    move2HomePage();
  }
  //update app global variables from metadata
  updateGlobalVariablesNMove2Home(metadataObj, isMove2Home){
  //save variables to global space
    glb_backend_uri = metadataObj.backend_uri;
    glb_gem_key = metadataObj.gem_key;
    glb_gem_uri = metadataObj.gem_uri;
    glb_hotel_booking_aff_id = metadataObj.hotel_booking_aff_id;
    glb_wonder_uri = metadataObj.wonder_uri;
    glb_wonder_alias_uri = metadataObj.wonder_alias_uri;
    glb_trip_uri = metadataObj.trip_uri;
    glb_home_cities = jsonDecode(metadataObj.home_cities);
    if (isMove2Home){
      move2HomePage();
    }
  }
  //
  move2HomePage() async{
    if (context.mounted) {
      await Future.delayed(const Duration(seconds: 1));  //delay screen 2 secs
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EntryPoint()));
    }
  }

  @override
  void initState() {
      super.initState();
    //fetchMetadata();
    move2HomePage();
  } 

  @override
  void dispose() {
    super.dispose();
  }

  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Expanded(
              flex: 14,
              child: PageView.builder(
                itemCount: 1,
                onPageChanged: (value) {
                  setState(() {
                    currentPage = value;
                  });
                },
                itemBuilder: (context, index) => OnboardContent(
                  illustration: "assets/images/ai_travel_logo_1024.png",
                  duration: 300,  //can wait 30 seconds, worst case is to update new cities
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
