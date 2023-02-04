// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.lightGreen),
      debugShowCheckedModeBanner: false,
      home: kIsWeb ? const SizedBox(width: 400, child: Home()) : const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late TextEditingController controller;
  // String controller.text= '';
  String answer = '';
  int openbracket = 0;
  int closingbracket = 0;

  var resultcolor = Colors.grey.shade900;
  var eqcolor = Colors.grey.shade900;
  double resultsize = 48;
  double eqsize = 48;

  var btheme = Colors.lightGreen;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final hei = MediaQuery.of(context).size.height; //screen height
    final wid = MediaQuery.of(context).size.width; //screen width
    const divider = Divider(
      height: 10,
      thickness: 0,
    );

    var verticalDivider = VerticalDivider(
      width: (1 - 0.21 * 4) / 5 * wid,
    );
    var verticalDivider2 = VerticalDivider(
      width: (1 - 0.21 * 4) / 10 * wid,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade600,
        elevation: 0,
        title: Text("",
            style: GoogleFonts.openSans(
                fontSize: 25,
                color: btheme.shade300,
                fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton(
            icon:
                Icon(Icons.more_vert_rounded, color: btheme.shade300, size: 30),
            position: PopupMenuPosition.under,
            color: btheme.shade200,
            elevation: 5,
            padding: EdgeInsets.all(10),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15.0))),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 0,
                textStyle: GoogleFonts.openSans(
                    fontSize: 20,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700),
                child: const Text(
                  "Theme",
                ),
              ),
              PopupMenuItem(
                value: 1,
                textStyle: GoogleFonts.openSans(
                    fontSize: 20,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700),
                child: const Text("About Us"),
              ),
              PopupMenuItem(
                value: 2,
                textStyle: GoogleFonts.openSans(
                    fontSize: 20,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700),
                child: const Text(
                  "Share App",
                ),
              ),
              PopupMenuItem(
                value: 3,
                textStyle: GoogleFonts.openSans(
                    fontSize: 20,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700),
                child: const Text("Rate Us"),
              ),
            ],
            onSelected: (value) async {
              // if value 1 show dialog
              if (value == 0) {
                // showTheme(wid, context);
                int hi = controller.selection.baseOffset;
                print("cursor => $hi");
                // if value 2 show dialog
              } else if (value == 1) {
                const url = 'https://github.com/NARIKODANHRIDUL/';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url';
                }
              } else if (value == 2) {
                Share.share(
                    "Check out Chess Timer App in Google PlayStore  https://play.google.com/store/apps/details?id=neriquest.chesstimer");
              } else if (value == 3) {
                const url =
                    'https://play.google.com/store/apps/details?id=neriquest.chesstimer';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url';
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Container(
                color: Colors.grey.shade600,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextField(
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: eqsize, color: eqcolor),
                          cursorColor: btheme.shade300,
                          textDirection: TextDirection.ltr,
                          cursorRadius: Radius.circular(12),
                          keyboardType: TextInputType.none,
                          controller: controller,
                          decoration: InputDecoration.collapsed(
                            hintText: '',
                            // counterText: '',
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: GestureDetector(
                            onLongPress: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: answer));
                              Fluttertoast.cancel();
                              toastmsg("$answer copied to Clipboard");
                            },
                            child: Text(
                              answer,
                              style: TextStyle(
                                color: answer == "Error"
                                    ? Color.fromARGB(255, 252, 114, 63)
                                    : answer == "Infinity" ||
                                            answer == "-Infinity"
                                        ? Color.fromARGB(255, 252, 114, 63)
                                        : answer == "Keep it real"
                                            ? Color.fromARGB(255, 252, 114, 63)
                                            : resultcolor,
                                fontSize: resultsize,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                divider,
                Row(
                  children: [
                    verticalDivider2,
                    extrabutton("√", wid),
                    verticalDivider2,
                    extrabutton("^", wid),
                    verticalDivider2,
                    extrabutton("!", wid),
                    verticalDivider2,
                    extrabutton("e", wid),
                    verticalDivider2,
                    extrabutton("log", wid),
                    verticalDivider2,
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    button("AC", wid),
                    verticalDivider,
                    button("( )", wid),
                    verticalDivider,
                    button("÷", wid),
                    verticalDivider,
                    button('×', wid),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    button("7", wid),
                    verticalDivider,
                    button("8", wid),
                    verticalDivider,
                    button("9", wid),
                    verticalDivider,
                    button("-", wid),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    button("4", wid),
                    verticalDivider,
                    button("5", wid),
                    verticalDivider,
                    button("6", wid),
                    verticalDivider,
                    button("+", wid),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    button("1", wid),
                    verticalDivider,
                    button("2", wid),
                    verticalDivider,
                    button("3", wid),
                    verticalDivider,
                    button("D", wid),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    button(".", wid),
                    verticalDivider,
                    button("0", wid),
                    verticalDivider,
                    button("=", wid),
                  ],
                ),
                divider,
              ],
            ),
          )
        ],
      ),
    );
  }

  ElevatedButton extrabutton(String tag, double wid) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if ((controller.text == '' || controller.text.endsWith("^")) &&
              tag == "^")
            null;
          else if (controller.text == '' && tag == "!")
            null;
          else if (controller.text != '' &&
              isnum(controller.text[controller.text.length - 1]) &&
              tag == "√") {
            controller.text += '*√';
          } else
            controller.text += tag;

          if (answer != '') {
            eqcolor = Colors.grey.shade900;
            resultcolor = Colors.grey.shade800;
            eqsize = 48;
            resultsize = 38;
          }
        });
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: tag == '^'
              ? EdgeInsets.only(top: wid * 0.20 / 10)
              : EdgeInsets.all(0),
          child: Text(
            tag,
            style:
                GoogleFonts.roboto(fontSize: 25, fontWeight: FontWeight.w400),
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
          fixedSize: Size(wid * 0.18, wid * 0.20 / 2.5),
          onPrimary: btheme.shade300,
          // primary: btheme.shade200.withOpacity(0.2),
          primary: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(300),
          )),
    );
  }

  ElevatedButton button(String tag, double wid) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            fixedSize: tag == "="
                ? Size(wid * (0.21 * 2 + ((1 - 0.21 * 4) / 5)), wid * 0.21)
                //width = width of 2 small button + gap between them
                : Size(wid * 0.21, wid * 0.21),
            onPrimary: tag == "="
                ? Colors.grey.shade800
                : (isOperator(tag) ? Colors.grey.shade900 : btheme.shade300),
            primary: tag == "="
                ? btheme.shade300
                : (isOperator(tag)
                    ? btheme.shade300
                    : Colors.grey.shade800.withOpacity(0.7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(300),
            )),
        onLongPress: () {
          if (tag == 'D') {
            setState(() {
              controller.text = '';
              answer = '';
            });
          }
        },
        onPressed: () {
          Fluttertoast.cancel();
          if (tag == 'AC') {
            setState(() {
              controller.text = '';
              answer = '';

              eqcolor = Colors.grey.shade900;
              resultcolor = Colors.grey.shade800;
              eqsize = 48;
              resultsize = 38;
            });
          } else if (tag == 'D') {
            setState(() {
              int cursor = controller.selection.baseOffset;

              int len = controller.text.length;
              print("cursor = $cursor  \n length = $len ");

              if ((cursor == len || cursor == -1) && controller.text != '') {
                if (controller.text.endsWith("log"))
                  controller.text =
                      controller.text.substring(0, controller.text.length - 3);
                else
                  controller.text =
                      controller.text.substring(0, controller.text.length - 1);
              } else if (controller.text != '' && controller.text != '') {
                cursor = cursor == -1 ? controller.text.length : cursor;
                print("Backspace => $cursor");
                controller.text = controller.text
                        .substring(0, controller.selection.baseOffset - 1) +
                    controller.text.substring(controller.selection.baseOffset);
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: cursor - 1),
                ); //to set cursor at its position
              }
              eqcolor = Colors.grey.shade900;
              resultcolor = Colors.grey.shade800;
              eqsize = 48;
              resultsize = 38;
            });
          } else if (tag == '=') {
            if (controller.text != '')
              calculate();
            else {
              Fluttertoast.cancel();
              Fluttertoast.showToast(
                  msg: "Type Some expression and try",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.grey.shade900,
                  textColor: btheme.shade300,
                  fontSize: 19.0);
            }

            eqcolor = Colors.grey.shade800;
            resultcolor = Colors.grey.shade900;
            eqsize = 38;
            resultsize = 48;
          } else if (tag == '( )') {
            setState(() {
              openbracket = controller.text.split("(").length - 1;
              closingbracket = controller.text.split(")").length - 1;

              if (openbracket == closingbracket ||
                  controller.text.endsWith('+') ||
                  controller.text.endsWith("-") ||
                  controller.text.endsWith("×") ||
                  controller.text.endsWith("÷") ||
                  controller.text.endsWith("(")) {
                (controller.text != '' &&
                        isnum(controller.text[controller.text.length - 1]))
                    // ^| else index error comes when we press () button when input is empty
                    ? controller.text += '×('
                    : (controller.text.endsWith('e'))
                        ? controller.text += '^1('
                        : controller.text += '(';
              } else if (openbracket > closingbracket &&
                  !controller.text.endsWith('(')) {
                controller.text += ')';
              }
            });
          } else {
            setState(() {
              if ((controller.text.endsWith('(') ||
                      controller.text == '' ||
                      controller.text == '-') &&
                  (tag == '+' || tag == '÷' || tag == '×')) {
                Fluttertoast.cancel();
                toastmsg("Invalid Input");
              } else if ((isOperator(tag) &&
                      isnum(controller.text[controller.text.length - 1]) ==
                          false) &&
                  !controller.text.endsWith('!') &&
                  !controller.text.endsWith(')') &&
                  !controller.text.endsWith('e')) {
                Fluttertoast.cancel();
                toastmsg("Invalid Input");
              } else
                controller.text += tag;
              /////////////////////////
              if (answer != '') {
                eqcolor = Colors.grey.shade900;
                resultcolor = Colors.grey.shade800;
                eqsize = 48;
                resultsize = 38;
              }
            });
          }
        },
        child: Center(
            child: tag == 'D'
                ? Icon(
                    Icons.backspace,
                    color: Colors.grey.shade900,
                  )
                : (tag == '×'
                    ? Icon(
                        Icons.close,
                        color: Colors.grey.shade900,
                        size: wid * 0.08,
                      )
                    : (tag == '+'
                        ? Icon(
                            Icons.add,
                            color: Colors.grey.shade900,
                            size: wid * 0.08,
                          )
                        : (tag == '-'
                            ? Icon(
                                Icons.horizontal_rule_rounded,
                                color: Colors.grey.shade900,
                                size: wid * 0.08,
                              )
                            : FittedBox(
                                child: Padding(
                                  padding: tag == '.'
                                      ? EdgeInsets.only(bottom: wid * 0.21 / 5)
                                      : EdgeInsets.all(0),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.roboto(
                                        fontSize: tag == '=' ||
                                                tag == '÷' ||
                                                tag == '.'
                                            ? 42
                                            : 32,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ))))));
  }

  void calculate() {
    String userInputToCalculate = controller.text;
    print("-----------------------------\nGiven => $controller.text");
    if (isOperator(userInputToCalculate[userInputToCalculate.length - 1]) ||
        userInputToCalculate.endsWith('√') == true ||
        userInputToCalculate.endsWith('^') == true) {
      userInputToCalculate =
          userInputToCalculate.substring(0, userInputToCalculate.length - 1);
    } // if last digit is an operator it will ignore it

    userInputToCalculate = userInputToCalculate.replaceAll('×', '*');
    userInputToCalculate = userInputToCalculate.replaceAll('÷', '/');

    while (userInputToCalculate.contains('√√') == true) {
      userInputToCalculate = userInputToCalculate.replaceAllMapped(
          RegExp(r'√√([^,]+)'), (match) => "√(√${match[1]})");
    } //when muultiple √√√ comes

    userInputToCalculate = userInputToCalculate.replaceAll('√', 'sqrt');

    // userInputToCalculate = userInputToCalculate.replaceAll('(*sqrt', '(sqrt');
    // // when someone wrote 4√2 => 4sqrt2 but 4*sqrt2 will work
    // userInputToCalculate = userInputToCalculate.replaceAll('**', '*');
    // if already someone wrote 4*√2 => it becomes 4**√2 (its an error), so cutting extra *
    if (userInputToCalculate.startsWith('*') == true) {
      userInputToCalculate = userInputToCalculate.substring(1);
    } //if √4 => it will not create two * but * and start will create problem, so cutting it

    userInputToCalculate = userInputToCalculate == 'e'
        ? userInputToCalculate = 'e^1'
        : userInputToCalculate; // e alone is giving error

//log(10, <expression>) needed so converting log to like this
    userInputToCalculate = userInputToCalculate.replaceAllMapped(
      RegExp(r"log([^,]+)"),
      (match) => "log(10, ${match.group(1)})",
    );
    print("calculating => $userInputToCalculate");
    try {
      Parser p = Parser();
      Expression exp = p.parse(userInputToCalculate);

      // Expression exp = p.parse(userInputToCalculate);
      // Bind variables:
      ContextModel cm = ContextModel();
      // Evaluate expression:
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      setState(() {
        answer = eval.toStringAsFixed(eval.truncateToDouble() == eval
            ? 0
            : eval.toString().length - eval.toString().indexOf(".") - 1);
        print("shooper $answer");
        print("answer = $answer");
        if (eval <= 0.000000000001 || eval >= 9999999999999)
          answer = eval.toStringAsExponential(6);
        else
          answer = eval.toStringAsFixed(11);

        if (answer.endsWith('.0000000000')) {
          answer = answer.substring(0, answer.length - 11);
        }

        //rempves all trailing zeroes after decimal
        answer = answer.toString().replaceAll(RegExp(r'([.]*0)(?!.*\d)'), '');
        print("final answer = $answer");
        answer = answer == 'NaN' ? 'Keep it real' : answer;
      });
    } catch (e) {
      setState(() {
        answer = controller.text == '' ? '0' : "Error";
      });
    }
  }

  void showTheme(double wid, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 40,
          backgroundColor: Colors.grey.shade800,
          shape: const RoundedRectangleBorder(
              side: BorderSide(width: 3, color: Colors.white12),
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
              child: Text(
            "Theme",
            style: GoogleFonts.openSans(
                color: Colors.grey.shade400,
                fontSize: 40,
                fontWeight: FontWeight.w800),
          )),
          contentPadding: EdgeInsets.all(0),
          titlePadding: EdgeInsets.only(top: 20, bottom: 10),
          insetPadding: EdgeInsets.all(0),
          // actionsOverflowButtonSpacing: 10,
          actionsPadding: EdgeInsets.all(5),
          actions: [
            FittedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      themebutton(wid, "Green", context),
                      VerticalDivider(
                        width: 10,
                      ),
                      themebutton(wid, "Blue", context),
                    ],
                  ),
                  Divider(
                    height: 10,
                  ),
                  Row(
                    children: [
                      themebutton(wid, "Red", context),
                      VerticalDivider(
                        width: 10,
                      ),
                      themebutton(wid, "Orange", context),
                      Divider(
                        height: 10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  ClipRRect themebutton(double wid, String color, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(30)),
      child: Container(
        height: wid * 0.35,
        width: wid * 0.35,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              primary: (color == "Green")
                  ? Colors.lightGreen.shade300
                  : (color == "Blue")
                      ? Colors.lightBlue.shade200
                      : (color == "Red")
                          ? Colors.redAccent.shade100
                          : Colors.orange.shade300),
          child: Text(
            color.toUpperCase(),
            style: GoogleFonts.openSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: (color == "Green")
                    ? Colors.lightGreen.shade600
                    : (color == "Blue")
                        ? Colors.lightBlue.shade600
                        : (color == "Red")
                            ? Colors.redAccent.shade200
                            : Colors.orange.shade600),
          ),
          onPressed: () {
            setState(() {
              if (color == "Green")
                btheme = Colors.lightGreen;
              else if (color == "Blue")
                btheme = Colors.lightBlue;
              else if (color == "Red")
                btheme = Colors.red;
              else
                btheme = Colors.orange;
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  bool isOperator(String value) {
    if (value == 'AC' ||
        value == 'D' ||
        value == '( )' ||
        value == '÷' ||
        value == '×' ||
        value == '-' ||
        value == '+') {
      return true;
    } else {
      return false;
    }
  }

  bool isnum(String value) {
    if (value == '1' ||
        value == '2' ||
        value == '3' ||
        value == '4' ||
        value == '5' ||
        value == '6' ||
        value == '7' ||
        value == '8' ||
        value == '9' ||
        value == '0') {
      return true;
    } else {
      return false;
    }
  }

  bool isextra(String value) {
    if (value == '√' || value == '^' || value == '!' || value == 'e') {
      return true;
    } else {
      return false;
    }
  }

  Future<bool?> toastmsg(String h) {
    return Fluttertoast.showToast(
        msg: h,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey.shade900,
        textColor: btheme.shade300,
        fontSize: 19.0);
  }
}
