import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:health_app1/screens/patient/doctor_profile.dart';

class ExploreList extends StatefulWidget {
  final String type;
  const ExploreList({Key? key, required this.type}) : super(key: key);

  @override
  State<ExploreList> createState() => _ExploreListState();
}

class _ExploreListState extends State<ExploreList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.type,
          // style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection("doctor")
              .where(
                "specialization",
                isEqualTo: widget.type.trim().toLowerCase(),
              )
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text("An error occurred while loading doctors."),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off,
                        size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      "No doctors found for this specialization.",
                      // style: GoogleFonts.lato(
                      //   fontSize: 16,
                      //   color: Colors.black54,
                      // ),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>?;

                if (data == null) return const SizedBox.shrink();
                final docid = data['id'];
                final String name = data['name'] ?? 'Unknown';
                final String specialization = data['specialization'] ?? 'N/A';
                final String profilePhoto = data['profilePhoto'] ?? '';
                final double rating =
                    double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;

                return InkWell(
                  onTap: () {
                    print("your document id is "+doc.id);
                    // ✅ PASS DOCUMENT ID CORRECTLY
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorProfile(doctor: name),
                            
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: profilePhoto.isNotEmpty
                                ? NetworkImage(profilePhoto)
                                : const NetworkImage(
                                    "https://cdn.icon-icons.com/icons2/1378/PNG/512/avatardefault_92824.png",
                                  ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  // style: GoogleFonts.lato(
                                  //   fontWeight: FontWeight.bold,
                                  //   fontSize: 16,
                                  // ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  specialization,
                                  // style: GoogleFonts.lato(
                                  //   color: Colors.black54,
                                  // ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      // style:
                                      //     GoogleFonts.lato(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}