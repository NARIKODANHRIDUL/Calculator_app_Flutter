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
  int openBracket = 0;
  int closingBracket = 0;
  String strBfrCursor = '';
  int cursor = 0;

  var resultColor = Colors.grey.shade900;
  var eqColor = Colors.grey.shade900;
  double resultSize = 38;
  double eqSize = 48;

  var bTheme = Colors.lightGreen;

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
                color: bTheme.shade300,
                fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton(
            icon:
                Icon(Icons.more_vert_rounded, color: bTheme.shade300, size: 30),
            position: PopupMenuPosition.under,
            color: bTheme.shade200,
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
              PopupMenuItem(
                  value: 4,
                  child: Transform.scale(
                    scale: 1.2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 135,
                        padding: EdgeInsets.all(0),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                              bTheme.shade300.withOpacity(0.4),
                              BlendMode.color),
                          child: Image(
                            image: AssetImage("images/neriquest.png"),
                          ),
                        ),
                      ),
                    ),
                  ))
            ],
            onSelected: (value) async {
              if (value == 0) {
                showTheme(wid, context);
              } else if (value == 1)
                openUrl('https://github.com/NARIKODANHRIDUL/');
              else if (value == 2)
                Share.share(
                    "Check out Chess Timer App in Google PlayStore  https://play.google.com/store/apps/details?id=neriquest.chesstimer");
              else if (value == 3)
                openUrl(
                    'https://play.google.com/store/apps/details?id=neriquest.chesstimer');
              else if (value == 4) toastMsg("Created by NeriQuest");
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
                          autofocus: true,
                          style: GoogleFonts.openSans(
                              fontSize: eqSize, color: eqColor),
                          cursorColor: bTheme.shade300,
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
                              toastMsg("$answer copied to Clipboard");
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
                                            : resultColor,
                                fontSize: resultSize,
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
                    extraButton("√", wid),
                    verticalDivider2,
                    extraButton("^", wid),
                    verticalDivider2,
                    extraButton("!", wid),
                    verticalDivider2,
                    extraButton("e", wid),
                    verticalDivider2,
                    extraButton("log", wid),
                    verticalDivider2,
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    mainButton("AC", wid),
                    verticalDivider,
                    mainButton("( )", wid),
                    verticalDivider,
                    mainButton("÷", wid),
                    verticalDivider,
                    mainButton('×', wid),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    mainButton("7", wid),
                    verticalDivider,
                    mainButton("8", wid),
                    verticalDivider,
                    mainButton("9", wid),
                    verticalDivider,
                    mainButton("-", wid),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    mainButton("4", wid),
                    verticalDivider,
                    mainButton("5", wid),
                    verticalDivider,
                    mainButton("6", wid),
                    verticalDivider,
                    mainButton("+", wid),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    mainButton("1", wid),
                    verticalDivider,
                    mainButton("2", wid),
                    verticalDivider,
                    mainButton("3", wid),
                    verticalDivider,
                    mainButton("D", wid),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    mainButton(".", wid),
                    verticalDivider,
                    mainButton("0", wid),
                    verticalDivider,
                    mainButton("=", wid),
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

  ElevatedButton extraButton(String tag, double wid) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          cursor = controller.selection.baseOffset;
          cursor = cursor == -1 ? controller.text.length : cursor;
          strBfrCursor = controller.text.substring(0, cursor);
          ////////////////
          if (tag == '√')
            typeIt('√');
          else if (tag == '^' &&
              strBfrCursor != '' &&
              (isNum(strBfrCursor[strBfrCursor.length - 1]) ||
                  strBfrCursor.endsWith(')') ||
                  strBfrCursor.endsWith('!') ||
                  strBfrCursor.endsWith('e')))
            typeIt('^(');
          else if (tag == '!' &&
              strBfrCursor != '' &&
              (isNum(strBfrCursor[strBfrCursor.length - 1]) ||
                  strBfrCursor.endsWith(')')))
            typeIt('!');
          else if (tag == 'e')
            typeIt('e');
          else if (tag == 'log') typeIt('㏒(');
          /////////////////
          if (answer != '') {
            eqColor = Colors.grey.shade900;
            resultColor = Colors.grey.shade800;
            eqSize = 48;
            resultSize = 38;
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
                GoogleFonts.nunito(fontSize: 25, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
          fixedSize: Size(wid * 0.18, wid * 0.20 / 2.5),
          onPrimary: bTheme.shade300,
          // primary: bTheme.shade200.withOpacity(0.2),
          primary: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(300),
          )),
    );
  }

  ElevatedButton mainButton(String tag, double wid) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            fixedSize: tag == "="
                ? Size(wid * (0.21 * 2 + ((1 - 0.21 * 4) / 5)), wid * 0.21)
                //width = width of 2 small mainButton + gap between them
                : Size(wid * 0.21, wid * 0.21),
            onPrimary: tag == "="
                ? Colors.grey.shade800
                : (isOperator(tag) ? Colors.grey.shade900 : bTheme.shade300),
            primary: tag == "="
                ? bTheme.shade300
                : (isOperator(tag)
                    ? bTheme.shade300
                    : Colors.grey.shade800.withOpacity(0.7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(300),
            )),
        onLongPress: () {
          if (tag == 'D') {
            setState(() {
              cursor = controller.selection.baseOffset;
              cursor = cursor == -1 ? controller.text.length : cursor;
              strBfrCursor = controller.text.substring(0, cursor);
              controller.text = controller.text.substring(cursor);
              freezeCursor(1);
            });
          }
        },
        onPressed: () {
          setState(() {
            ///////////////////////////
            cursor = controller.selection.baseOffset;
            cursor = cursor == -1 ? controller.text.length : cursor;
            strBfrCursor = controller.text.substring(0, cursor);
            ///////////////////////////
            if (tag == 'AC') {
              controller.text = '';
              answer = '';
              eqColor = Colors.grey.shade900;
              resultColor = Colors.grey.shade800;
              eqSize = 48;
              resultSize = 38;
              //////////////////////
            } else if (tag == 'D') {
              if (controller.text != '') {
                controller.text = controller.text
                        .substring(0, controller.selection.baseOffset - 1) +
                    controller.text.substring(controller.selection.baseOffset);
                freezeCursor(cursor);
              }
              //////////////////////
              eqColor = Colors.grey.shade900;
              resultColor = Colors.grey.shade800;
              eqSize = 48;
              resultSize = 38;
              //////////////////////
            } else if (tag == '=') {
              if (controller.text != '') {
                calculate();
                cursor = controller.selection.baseOffset;
                print('cursor >> $cursor');
              } else {
                toastMsg("Type Some expression and try");
              }
              ////////////////
              eqColor = Colors.grey.shade800;
              resultColor = Colors.grey.shade900;
              eqSize = 38;
              resultSize = 48;
              /////////////////
            } else if (tag == '( )') {
              openBracket = strBfrCursor.split("(").length - 1;
              closingBracket = strBfrCursor.split(")").length - 1;

              if (openBracket == closingBracket ||
                  strBfrCursor.endsWith('+') ||
                  strBfrCursor.endsWith("-") ||
                  strBfrCursor.endsWith("×") ||
                  strBfrCursor.endsWith("÷") ||
                  strBfrCursor.endsWith("(")) {
                (strBfrCursor != '' &&
                        isNum(strBfrCursor[strBfrCursor.length - 1]))
                    // ^| else index error comes when we press () mainButton when input is empty
                    ? typeIt('×(')
                    : (strBfrCursor.endsWith('e'))
                        ? typeIt('^1(')
                        : typeIt('(');
              } else if (openBracket > closingBracket &&
                  !strBfrCursor.endsWith('(')) {
                typeIt(')');
              }
              /////////////////////
            } else if (tag == '-') {
              if (strBfrCursor.endsWith('-'))
                null; //will not type - if there is already -
              else if (strBfrCursor.endsWith('÷') ||
                  strBfrCursor.endsWith('×') ||
                  strBfrCursor.endsWith('+')) {
                controller.text = controller.text
                        .substring(0, controller.selection.baseOffset - 1) +
                    controller.text.substring(controller.selection.baseOffset);
                freezeCursor(cursor);
                typeIt('–');
              } else
                typeIt('–');
              ///////////////////////
            } else if (isNum(tag) || tag == '.') {
              if (tag == '.' &&
                  (strBfrCursor.endsWith('(') || strBfrCursor.endsWith(')')))
                toastMsg("Invalid Input");
              else
                typeIt(tag);
            } else {
              if (strBfrCursor != '–' &&
                  (strBfrCursor.endsWith('÷') ||
                      strBfrCursor.endsWith('×') ||
                      strBfrCursor.endsWith('–') ||
                      strBfrCursor.endsWith('+'))) {
                controller.text = controller.text
                        .substring(0, controller.selection.baseOffset - 1) +
                    controller.text.substring(controller.selection.baseOffset);
                freezeCursor(cursor);
                typeIt(tag);
              } else if ((strBfrCursor != '' &&
                  (isNum(strBfrCursor[strBfrCursor.length - 1]) ||
                      strBfrCursor.endsWith(')'))))
                typeIt(tag);
              else
                toastMsg("Invalid Input");

              /////////////////////////
              if (answer != '') {
                eqColor = Colors.grey.shade900;
                resultColor = Colors.grey.shade800;
                eqSize = 48;
                resultSize = 38;
              }
            }
          });
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
                                    style: GoogleFonts.nunito(
                                        fontSize: tag == '=' ||
                                                tag == '÷' ||
                                                tag == '.'
                                            ? 42
                                            : 32,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ))))));
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
            "THEME",
            style: GoogleFonts.abel(
                color: Colors.grey.shade400,
                fontSize: 40,
                fontWeight: FontWeight.w900),
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
                      themeButton(wid, "Green", context),
                      VerticalDivider(
                        width: 10,
                      ),
                      themeButton(wid, "Blue", context),
                    ],
                  ),
                  Divider(
                    height: 10,
                  ),
                  Row(
                    children: [
                      themeButton(wid, "Red", context),
                      VerticalDivider(
                        width: 10,
                      ),
                      themeButton(wid, "Orange", context),
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

  ClipRRect themeButton(double wid, String color, BuildContext context) {
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
                bTheme = Colors.lightGreen;
              else if (color == "Blue")
                bTheme = Colors.lightBlue;
              else if (color == "Red")
                bTheme = Colors.red;
              else
                bTheme = Colors.orange;
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void calculate() {
    String userInputToCalculate = controller.text;
    print("-----------------------------\nGiven => $userInputToCalculate");
    ////////////////////////////////
    if (isOperator(userInputToCalculate[userInputToCalculate.length - 1]) ||
        userInputToCalculate.endsWith('√') ||
        userInputToCalculate.endsWith('^')) {
      userInputToCalculate =
          userInputToCalculate.substring(0, userInputToCalculate.length - 1);
    } // if last digit is an operator it will ignore it

    ////////////////////////////////
    userInputToCalculate = userInputToCalculate.replaceAll('×', '*');
    userInputToCalculate = userInputToCalculate.replaceAll('÷', '/');
    userInputToCalculate = userInputToCalculate.replaceAll('–', '-');
    userInputToCalculate = userInputToCalculate.replaceAll('㏒', 'log');
    ////////////////////////////////
    while (userInputToCalculate.contains('√√')) {
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
        print("eval $eval");
        answer = eval.toStringAsFixed(eval.truncateToDouble() == eval
            ? 0
            : eval.toString().length - eval.toString().indexOf(".") - 1);

        print("answer = $answer");
        answer = eval.toString();
        if (eval <= 0.000000000001 || eval >= 9999999999999) {
          int index = answer.indexOf("e");
          print("i = $index");
        }

        // if (answer.endsWith('.00000000000')) {
        //   answer = answer.substring(0, answer.length - 12);
        // }
        print("1 answer = $eval");
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

  bool isNum(String value) {
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

  bool isExtra(String value) {
    if (value == '√' || value == '^' || value == '!' || value == 'e') {
      return true;
    } else {
      return false;
    }
  }

  void typeIt(String str) {
    cursor = controller.selection.baseOffset;
    cursor = cursor == -1 ? controller.text.length : cursor;
    print("cursor = $cursor\n");
    controller.text = controller.text.substring(0, cursor) +
        str +
        controller.text.substring(cursor);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: cursor + str.length));
  }

  void openUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void freezeCursor(int cursor) {
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: cursor - 1),
    );
  }

  void toastMsg(String h) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: h,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey.shade900,
        textColor: bTheme.shade300,
        fontSize: 19.0);
  }

///////////////////////
}//////THE END/////////
///////////////////////

