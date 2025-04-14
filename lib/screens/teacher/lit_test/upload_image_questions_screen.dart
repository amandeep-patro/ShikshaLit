import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadImageQuestionsScreen extends StatelessWidget {
  const UploadImageQuestionsScreen({super.key});

  Future<void> _uploadQuestions(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    final questions = [
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Giraffe_at_Working_with_Wildlife.jpg/960px-Giraffe_at_Working_with_Wildlife.jpg?20240123121559',
        'correctAnswer': 'Giraffe',
        'options': ['Elephant', 'Giraffe', 'Lion', 'Horse'],
      },
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Fire_engine_ZIL-131_2009_G1.jpg/1200px-Fire_engine_ZIL-131_2009_G1.jpg?20091115145025',
        'correctAnswer': 'Fire Truck',
        'options': ['Ambulance', 'Police Car', 'Fire Truck', 'Bus'],
      },
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/5/50/Toaster.png?20230421024958',
        'correctAnswer': 'Toaster',
        'options': ['Microwave', 'Toaster', 'Oven', 'Kettle'],
      },
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Hammer-1.jpg/1200px-Hammer-1.jpg?20090218222808',
        'correctAnswer': 'Hammer',
        'options': ['Hammer', 'Screwdriver', 'Wrench', 'Drill'],
      },
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Seebruecke_Prerow_002.jpg/1200px-Seebruecke_Prerow_002.jpg?20080220155622',
        'correctAnswer': 'Tree',
        'options': ['Tree', 'Bush', 'Flower', 'Cactus'],
      },
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/01_Rotating_Ceiling_fan_at_640th_of_a_second.JPG/1200px-01_Rotating_Ceiling_fan_at_640th_of_a_second.JPG?20160130091632',
        'correctAnswer': 'Ceiling Fan',
        'options': ['Ceiling Fan', 'Air Conditioner', 'Heater', 'Bulb'],
      },
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Cat_Iran.jpg/960px-Cat_Iran.jpg?20120911114814',
        'correctAnswer': 'Cat',
        'options': ['Dog', 'Rabbit', 'Cat', 'Tiger'],
      },
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Air-to-air_photo_of_a_Sukhoi_Superjet_100_%28RA-97004%29_over_Italy.jpg/1200px-Air-to-air_photo_of_a_Sukhoi_Superjet_100_%28RA-97004%29_over_Italy.jpg?20131103210155',
        'correctAnswer': 'Airplane',
        'options': ['Airplane', 'Helicopter', 'Jet', 'Drone'],
      },
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Bicycle%2C_belonging_to_the_bicycle-sharing_system_Bolt_in_Kaunas%2C_Lithuania_in_2022.jpg/1200px-Bicycle%2C_belonging_to_the_bicycle-sharing_system_Bolt_in_Kaunas%2C_Lithuania_in_2022.jpg?20221124213525',
        'correctAnswer': 'Bicycle',
        'options': ['Scooter', 'Motorbike', 'Bicycle', 'Car'],
      },
      {
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Sunflower_sky_backdrop.jpg/1082px-Sunflower_sky_backdrop.jpg?20090821034612',
        'correctAnswer': 'Sunflower',
        'options': ['Rose', 'Sunflower', 'Lily', 'Daisy'],
      },
    ];

    try {
      await firestore
          .collection('literacycheck')
          .doc('image_recognition')
          .set({'questions': questions, 'timestamp': FieldValue.serverTimestamp()});

      print('✅ Data uploaded successfully.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Questions uploaded successfully!')),
      );
    } catch (e, stack) {
      print('❌ Error uploading data: $e');
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to upload questions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Image Questions'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _uploadQuestions(context),
          icon: Icon(Icons.cloud_upload),
          label: Text('Upload to Firebase'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }
}
