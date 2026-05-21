import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/screens/diseasedetail.dart';

class Disease extends StatefulWidget {
  const Disease({Key? key}) : super(key: key);

  @override
  State<Disease> createState() => _DiseaseState();
}

class _DiseaseState extends State<Disease> {
  final List<Map<String, String>> _diseases = [
    {
      'Name': 'Influenza',
      'Symptoms': 'Fever, cough, sore throat',
    },
    {
      'Name': 'Dengue',
      'Symptoms': 'High fever, joint pain, rash',
    },
    {
      'Name': 'Covid-19',
      'Symptoms': 'Cough, fever, loss of taste/smell',
    },
    {
      'Name': 'Malaria',
      'Symptoms': 'Chills, fever, sweating',
    },
    {
      'Name': 'Asthma',
      'Symptoms': 'Shortness of breath, wheezing',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Diseases',
          // style: GoogleFonts.lato(
          //   color: Colors.black,
          //   fontSize: 20,
          //   fontWeight: FontWeight.bold,
          // ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _diseases.length,
        itemBuilder: (context, index) {
          final disease = _diseases[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 10,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black87,
                  width: 0.2,
                ),
              ),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DiseaseDetail(disease: disease['Name'] ?? ''),
                  ),
                );
              },
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        disease['Name'] ?? 'Unknown',
                        // style: GoogleFonts.lato(
                        //   fontWeight: FontWeight.bold,
                        //   fontSize: 16,
                        //   color: Colors.black87,
                        // ),
                      ),
                      Text(
                        disease['Symptoms'] ?? '',
                        // style: GoogleFonts.lato(
                        //     fontSize: 14, color: Colors.black54),
                      ),
                    ],
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
