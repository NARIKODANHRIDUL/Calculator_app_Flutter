import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

// import 'package:fluttertoast/fluttertoast.dart';
//import 'main.dart';

// ignore: must_be_immutable
class about extends StatelessWidget {
  bool isDark;
  about({
        Key? key,
        required this.isDark,
      })
      : super(key: key);
  Color bgcolor = Color.fromRGBO(16, 16, 16, 1);
  Color txtcolor = Colors.grey.shade300;
  Color title = Color.fromARGB(228, 255, 255, 255);
  Color subtitle = Colors.white70;
  Color greyy = Colors.black;
  int s = 0;
  @override
  Widget build(BuildContext context) {
    // final hei = MediaQuery.of(context).size.height;
    final wid = MediaQuery.of(context).size.width;

    if (isDark == false) {
      bgcolor = Colors.grey.shade50;
      txtcolor = Colors.grey.shade900;
      title = Colors.grey.shade900;
      subtitle = Colors.grey.shade700;
    }
    

    return Scaffold(
        backgroundColor: greyy,
        // floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
        extendBodyBehindAppBar: true,
        body: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              leading: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                    
                      borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(18),
                          topRight: Radius.circular(18))),
                  backgroundColor: Colors.grey,
                  elevation: 0,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: greyy,
                  size: 30,
                ),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20)),
                ),
              ),
              title: Row(children: [
                Padding(
                  padding: EdgeInsets.only(left: 0.075 * wid, right: 7),
                  child: Text("About App",
                      // textAlign: TextAlign.start,
                      style: GoogleFonts.righteous(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      )),
                ),
                Icon(
                  Icons.info_outline,
                  size: 28,
                  color: Colors.grey
                ),
              ]),
              backgroundColor: Colors.transparent,
              floating: true,
            ),
          ],

          body: Stack(children: [
            ListView(children: [
              Container(
                width: wid,
                color: greyy,
                child: Image(
                  image: AssetImage("images/calc.png"),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Center(
                child: Text(
                  "Calculator",
                  style: GoogleFonts.viga(
                      color: Colors.grey.shade800,
                      fontSize: 25,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Center(
                  child: Text(
                "Made in India, with love & passion",
                style: GoogleFonts.poppins(color: Colors.grey.shade700),
              )),
              SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    color: bgcolor),
                child: Column(
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.person,
                        size: 30,
                        color: title,
                      ),
                      onTap: () {
                        s = s + 1;
                        Fluttertoast.cancel();
                        if (s >= 2 && s <= 5) {
                          int g = 5 - s;
                          Fluttertoast.showToast(msg: "$g");
                        } else if (s == 6 || s == 7) {
                          Fluttertoast.cancel();
                          Fluttertoast.showToast(
                              msg: "Long press and try again 😉");
                        }
                      },
                      onLongPress: () async {
                        if (s == 5) {
                          const url =
                              'https://www.linkedin.com/in/narikodanhridul';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          } else {
                            throw 'Could not launch $url';
                          }
                        } else {
                          s = 0;
                          Fluttertoast.cancel();
                          Fluttertoast.showToast(msg: "Narikodan");
                        }
                      },
                      minLeadingWidth: 0,
                      title: Text(
                        "Lead Developer",
                        style: GoogleFonts.viga(
                            color: title,
                            fontSize: 20,
                            fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "Narikodan aka NeriQuest",
                        style: GoogleFonts.firaSans(
                          color: subtitle,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.info,
                        size: 30,
                        color: title,
                      ),
                      minLeadingWidth: 0,
                      title: Text(
                        "App Version",
                        style: GoogleFonts.viga(
                            color: title,
                            fontSize: 20,
                            fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "1.0.6+7",
                        style: GoogleFonts.firaSans(
                          color: subtitle,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.published_with_changes_rounded,
                        size: 30,
                        color: title,
                      ),
                      minLeadingWidth: 0,
                      title: Text(
                        "Released On",
                        style: GoogleFonts.viga(
                            color: title,
                            fontSize: 20,
                            fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "March 23, 2022",
                        style: GoogleFonts.firaSans(
                          color: subtitle,
                        ),
                      ),
                    ),
                    // ListTile(
                    //   leading: Icon(
                    //     Icons.favorite,
                    //     size: 30,
                    //     color: title,
                    //   ),
                    //   minLeadingWidth: 0,
                    //   title: Text(
                    //     "Donate",
                    //     style: GoogleFonts.viga(
                    //         color: title,
                    //         fontSize: 20,
                    //         fontWeight: FontWeight.w500),
                    //   ),
                    //   subtitle: Text(
                    //     "Support development",
                    //     style: GoogleFonts.firaSans(
                    //       color: subtitle,
                    //     ),
                    //   ),
                    // ),
                    ListTile(
                      leading: Icon(
                        Icons.star,
                        size: 30,
                        color: title,
                      ),
                      minLeadingWidth: 0,
                      title: Text(
                        "Rate Us",
                        style: GoogleFonts.viga(
                            color: title,
                            fontSize: 20,
                            fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "Enjoying Calculator ?",
                        style: GoogleFonts.firaSans(
                          color: subtitle,
                        ),
                      ),
                      onTap: () async {
                        const url =
                            'https://play.google.com/store/apps/details?id=neriquest.calculator';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.description_rounded,
                        size: 30,
                        color: title,
                      ),
                      minLeadingWidth: 0,
                      title: Text(
                        "Privacy policy",
                        style: GoogleFonts.viga(
                            color: title,
                            fontSize: 20,
                            fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "Your privacy matters",
                        style: GoogleFonts.firaSans(
                          color: subtitle,
                        ),
                      ),
                      onTap: () async {
                        const url =
                            'https://github.com/NeriQuest/neriquest.github.io/blob/main/README.md';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                    ),
                    Divider(
                      color: subtitle,
                      indent: 20,
                      endIndent: 20,
                      height: 25,
                      thickness: 1,
                    ),
                    SizedBox(height: 10),
                    Padding(
                        padding: const EdgeInsets.only(
                            bottom: 15.0, left: 15.0, right: 15.0, top: 5),
                        child: RichText(
                            textAlign: TextAlign.justify,
                            text: TextSpan(
                                style: TextStyle(
                                  fontSize: (0.052 * wid),
                                  color: txtcolor,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '''
 NeriQuest Calculator is a free, easy to use app with modern UI for making all your calculations along with a base converter.

All Features in one go:
- Calculation with expression input
- Base converter
- History
- modern UI
- User friendly interface
- Dark/Light mode

Thank you         
          
  ''',
                                    style: GoogleFonts.firaSans(
                                      fontSize: (0.051 * wid),
                                      color: txtcolor.withOpacity(0.7),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '''© NeriQuest\n English (United States)''',
                                    style: TextStyle(
                                      fontSize: (0.051 * wid),
                                      color: txtcolor.withOpacity(0.7),
                                    ),
                                  )
                                ]))),
                    Transform.scale(
                      scale: 0.8,
                      child: Image(
                        image: AssetImage("images/neriquest.png"),
                      ),
                    ),
                    Container(
                      height: 60,
                    )
                  ],
                ),
              ),
            ]),

          ]),

          //
          //
          //
          //
          //BACKGROUND
        ));
  } //splash = android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
}
//image: const DecorationImage(
//                       image: AssetImage(
//                           'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'),
//                      fit: BoxFit.fill),
